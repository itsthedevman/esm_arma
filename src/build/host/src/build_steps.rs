use crate::*;

use colored::*;
use common::{BuildError, BuildResult, Command};
use compiler::Compiler;
use lazy_static::lazy_static;
use regex::Regex;
use serde::{Deserialize, Serialize};
use std::{fs, path::Path, thread, time::Duration};

pub fn start_container(_builder: &mut Builder) -> BuildResult {
    if container_status()? != "running" {
        System::new()
            .command("docker")
            .arguments(&["compose", "up", "-d"])
            .execute()?;
    }

    Ok(())
}

pub fn container_status() -> Result<String, BuildError> {
    Ok(System::new()
        .command("docker")
        .arguments(&[
            "container",
            "inspect",
            "-f",
            "\"{{.State.Status}}\"",
            ARMA_CONTAINER,
        ])
        .add_detection("running")
        .execute()?
        .trim_end()
        .to_string())
}

pub fn wait_for_container(_builder: &mut Builder) -> BuildResult {
    const TIMEOUT: i32 = 30; // Seconds
    let mut counter = 0;

    loop {
        if container_status()? == "running" || counter >= TIMEOUT {
            break;
        }

        counter += 1;
        thread::sleep(Duration::from_secs(1));
    }

    if counter >= TIMEOUT {
        return Err("Timed out - The docker image never booted"
            .to_string()
            .into());
    }

    Ok(())
}

pub fn update_arma(builder: &mut Builder) -> BuildResult {
    let script = format!(
        "cd /steamcmd && ./steamcmd.sh +force_install_dir {ARMA_PATH} +login {steam_username} {steam_password} {update} +quit",
        update = "+app_update 233780 validate",
        steam_username = builder.config.server.steam_user,
        steam_password = builder.config.server.steam_password
    );

    System::new()
        .command("bash")
        .arguments(&[
            "-c",
            &format!("docker exec -t {ARMA_CONTAINER} /bin/bash -c \"{script}\""),
        ])
        .print_as("steamcmd")
        .print_stdout()
        .execute()?;

    Ok(())
}

pub fn prepare_receiver(builder: &mut Builder) -> BuildResult {
    stop_receiver()?;

    if builder.rebuild_receiver() {
        build_receiver(builder)?;
    }

    start_receiver()
}

pub fn build_receiver(builder: &mut Builder) -> BuildResult {
    let git_path = builder.local_git_path.to_string_lossy();

    // Build receiver
    System::new()
        .command("cargo")
        .arguments(&[
            "build",
            "--release",
            "--manifest-path",
            &format!("{git_path}/src/build/receiver/Cargo.toml"),
        ])
        .add_error_detection("no such")
        .print()
        .execute()?;

    // Copy to container
    System::new()
        .command("docker")
        .arguments(&[
            "compose",
            "cp",
            &format!("{git_path}/target/release/receiver"),
            &format!("{ARMA_SERVICE}:{ARMA_PATH}"),
        ])
        .add_error_detection("no such")
        .print()
        .execute()?;

    // Create script to run receiver in container
    let receiver_script = format!(
        r#"#!/bin/bash
/arma3server/receiver \
    --host=127.0.0.1:54321 \
    --database-uri={} \
    --a3-server-path=/arma3server \
    --a3-server-args=\"{}\" \
    >> receiver.log
"#,
        builder.config.server.mysql_uri,
        builder
            .config
            .server
            .server_args
            .iter()
            .map(|arg| format!("-{arg}"))
            .collect::<Vec<String>>()
            .join(" ")
    );

    // Send receiver script and setup for execution
    System::new()
        .command("docker")
        .arguments(&[
            "exec",
            "-t",
            ARMA_CONTAINER,
            "/bin/bash",
            "-c",
            &format!("echo \"{receiver_script}\" > /arma3server/start_receiver.sh && chmod +x /arma3server/start_receiver.sh && chmod +x /arma3server/receiver"),
        ])
        .add_error_detection("no such")
        .print_as("writing start script")
        .print()
        .execute()?;

    Ok(())
}

pub fn prepare_to_build(builder: &mut Builder) -> BuildResult {
    kill_arma(builder)?;
    detect_first_build(builder)?;
    prepare_directories(builder)?;
    transfer_mikeros_tools(builder)?;
    create_server_config(builder)?;
    create_esm_key_file(builder)
}

pub fn kill_arma(builder: &mut Builder) -> BuildResult {
    builder.build_server.send(Command::KillArma)?;
    Ok(())
}

pub fn detect_first_build(builder: &mut Builder) -> BuildResult {
    let extension_file_name = match builder.args.build_arch() {
        BuildArch::X32 => "esm",
        BuildArch::X64 => "esm_x64",
    };

    let mut files_to_check: Vec<String> = ADDONS
        .iter()
        .map(|addon| format!(r"addons\{addon}.pbo"))
        .collect();

    if matches!(builder.args.build_env(), BuildEnv::Test) {
        files_to_check.push(r"addons\esm_test.pbo".to_string());
    }

    let script = match builder.args.build_os() {
        BuildOS::Windows => {
            files_to_check.push(format!("{extension_file_name}.dll"));

            files_to_check
                .iter()
                .map(|path| {
                    format!(
                        r#"if (![System.IO.File]::Exists("{server_path}\@esm\{path}")) {{ return "rebuild"; }}"#,
                        server_path = builder.remote.server_path
                    )
                })
                .collect::<Vec<String>>()
                .join("\n")
        }
        BuildOS::Linux => {
            files_to_check.push(format!("{extension_file_name}.so"));

            let checks = files_to_check
                .iter()
                .map(|path| {
                    format!(
                        r#"[[ ! -f "{server_path}/@esm/{path}" ]]"#,
                        server_path = builder.remote.server_path
                    )
                })
                .collect::<Vec<String>>()
                .join(" || ");

            format!("({checks}) && echo \"rebuild\"")
        }
    };

    let result = System::new()
        .script(script)
        .add_detection("rebuild")
        .execute_remote(&builder.build_server)?;

    if result == *"rebuild" {
        // This may be a first build - build all the things!
        builder.args.force = true;
    }

    Ok(())
}

pub fn prepare_directories(builder: &mut Builder) -> BuildResult {
    ////////////////////
    // Local directories
    // Keeps the files around for viewing when building the extension by itself
    if builder.rebuild_mod() {
        let esm_path = builder.local_build_path.join("@esm");

        // Delete @esm and recreate it
        if esm_path.exists() {
            fs::remove_dir_all(&esm_path)?;
            fs::create_dir_all(&esm_path)?;
        }

        // Create @esm/addons
        let addons_path = esm_path.join("addons");
        if !addons_path.exists() {
            fs::create_dir_all(&addons_path)?;
        }
    }

    // Remove some build files
    let paths = vec![
        "@esm.zip",
        "windows.zip",
        "linux.zip",
        "esm.zip",
        ".esm-build-command",
        ".esm-build-command-result",
    ];

    for path in paths {
        let path = builder.local_build_path.join(path);
        if path.exists() && path.is_file() {
            fs::remove_file(&path)?;
        }
    }

    /////////////////////
    // Remote directories
    lazy_static! {
        static ref PROFILES_REGEX: Regex = Regex::new(r#"-profiles=(\w+)"#).unwrap();
    };

    let profile_name = match PROFILES_REGEX.captures(&builder.remote.server_args) {
        Some(c) => match c.get(1) {
            Some(n) => n.as_str(),
            None => return Err(
                "\"-profiles\" must be provided in the server args. This is required for log streaming"
                    .to_string()
                    .into(),
            ),
        },
        None => return Err(
            "\"-profiles\" must be provided in the server args. This is required for log streaming"
                .to_string()
                .into(),
        ),
    };

    let script = match builder.args.build_os() {
        BuildOS::Windows => {
            format!(
                r#"
                    Remove-Item "{server_path}\{profile_name}\*.log" -ErrorAction SilentlyContinue;
                    Remove-Item "{server_path}\{profile_name}\*.rpt" -ErrorAction SilentlyContinue;
                    Remove-Item "{server_path}\{profile_name}\*.bidmp" -ErrorAction SilentlyContinue;
                    Remove-Item "{server_path}\{profile_name}\*.mdmp" -ErrorAction SilentlyContinue;

                    New-Item -Path "{build_path}\esm" -ItemType Directory;
                    New-Item -Path "{build_path}\@esm" -ItemType Directory;
                    New-Item -Path "{build_path}\@esm\addons" -ItemType Directory;
                    New-Item -Path "{server_path}\@esm" -ItemType Directory;
                    New-Item -Path "{server_path}\@esm\addons" -ItemType Directory;
                "#,
                build_path = builder.remote_build_path_str(),
                server_path = builder.remote.server_path,
            )
        }
        BuildOS::Linux => format!(
            r#"
                rm -f "{server_path}/{profile_name}/*.log";
                rm -f "{server_path}/{profile_name}/*.rpt";
                rm -f "{server_path}/{profile_name}/*.bidmp";
                rm -f "{server_path}/{profile_name}/*.mdmp";
                rm -fr "{server_path}/@esm";

                mkdir -p "{server_path}/@esm/addons";
            "#,
            server_path = builder.remote.server_path,
        ),
    };

    System::new()
        .script(script)
        .add_error_detection("error")
        .print()
        .execute_remote(&builder.build_server)?;

    Ok(())
}

pub fn transfer_mikeros_tools(builder: &mut Builder) -> BuildResult {
    let mikero_path = builder
        .local_git_path
        .join("tools")
        .join("pbo_tools")
        .join(builder.args.build_os().to_string());

    Directory::transfer(builder, mikero_path, builder.remote_build_path().to_owned())
}

pub fn create_server_config(builder: &mut Builder) -> BuildResult {
    #[derive(Debug, PartialEq, Serialize, Deserialize)]
    struct Config {
        connection_url: String,
        log_level: String,
        env: String,
        log_output: String,
    }

    let config = Config {
        connection_url: builder.args.bot_host().to_string(),
        log_level: builder.args.log_level().to_string(),
        env: builder.args.build_env().to_string(),
        log_output: "rpt".into(),
    };

    let config_yaml = serde_yaml::to_vec(&config)?;
    fs::write(
        builder
            .local_build_path
            .join("config.yml")
            .to_string_lossy()
            .to_string(),
        config_yaml,
    )?;

    crate::File::transfer(
        builder,
        builder.local_build_path.to_owned(),
        builder.remote_build_path().join("@esm"),
        "config.yml",
    )?;

    Ok(())
}

pub fn create_esm_key_file(builder: &mut Builder) -> BuildResult {
    let mut connection = builder.redis.get_connection()?;
    let mut last_key_received = String::new();

    // Moved to a thread so this can happen over and over again for testing purposes
    let build_server = builder.build_server.clone();
    thread::spawn(move || loop {
        let key: Option<String> = redis::cmd("GET")
            .arg(REDIS_SERVER_KEY)
            .query(&mut connection)
            .unwrap();

        let Some(key) = key else {
                thread::sleep(Duration::from_millis(500));
                continue;
            };

        if key == last_key_received {
            thread::sleep(Duration::from_millis(500));
            continue;
        }

        if let Err(e) = build_server.send(Command::Key(key.to_owned())) {
            println!(
                "{} - {} - {}",
                "<esm_bt>".blue().bold(),
                "failed to set key".red().bold(),
                e
            );

            continue;
        };

        last_key_received = key.to_owned();
    });

    Ok(())
}

pub fn check_for_p_drive(builder: &mut Builder) -> BuildResult {
    assert!(matches!(builder.args.build_os(), BuildOS::Windows));

    let script = r#"
            if (Get-PSDrive P -ErrorAction SilentlyContinue) {{
                "p_drive_mounted";
            }} else {{
                "p_drive_not_mounted";
            }}
        "#;

    let result = System::new()
        .script(script)
        .add_detection("p_drive_mounted")
        .execute_remote(&builder.build_server)?;

    // Continue building
    if result == "p_drive_mounted" {
        return Ok(());
    }

    // WorkDrive.exe will keep a window open that requires user input
    println!("{}", "paused\nWaiting for input...".yellow());
    println!("Please confirm Window's UAC and then press any key on the window that WorkDrive has opened");

    let script = format!(
        r#"
                Start-Process -Wait -FilePath "{build_path}\windows\WorkDrive.exe" -ArgumentList "/Mount";

                if (Get-PSDrive P -ErrorAction SilentlyContinue) {{
                    "p_drive_mounted";
                }} else {{
                    "p_drive_not_mounted";
                }}
            "#,
        build_path = builder.remote_build_path_str(),
    );

    System::new()
        .command(script)
        .add_error_detection("p_drive_not_mounted")
        .execute_remote(&builder.build_server)?;

    Ok(())
}

pub fn build_mod(builder: &mut Builder) -> BuildResult {
    compile_mod(builder)?;

    let mut extra_addons = vec![];
    if matches!(builder.args.build_env(), BuildEnv::Test) {
        extra_addons.push("esm_test");
    }

    for addon in ADDONS.iter().chain(extra_addons.iter()) {
        if !builder.rebuild_addon(addon) {
            continue;
        }

        let script = match builder.args.build_os() {
            BuildOS::Linux => {
                format!(
                    r#"
source_dir="{build_path}/@esm/addons/{addon}";
destination_file="{build_path}/@esm/addons/{addon}.pbo";
{build_path}/linux/bin/makepbo -P -@={addon} "$source_dir" "$destination_file";

[[ ! -f "$destination_file" ]] && return "Failed to build - $destination_file does not exist";

rm -rf $source_dir;
"#,
                    build_path = builder.remote_build_path_str(),
                )
            }
            BuildOS::Windows => {
                // The "root" is what matters here. The root needs to be P: drive
                format!(
                    r#"
if ([System.IO.Directory]::Exists("P:\{addon}")) {{
    Remove-Item -Path "P:\{addon}" -Recurse;
}}

Move-Item -Force -Path "{build_path}\@esm\addons\{addon}" -Destination "P:";
Start-Process -Wait -NoNewWindow -FilePath "{build_path}\windows\MakePbo.exe" -ArgumentList "-P", "P:\{addon}", "{build_path}\@esm\addons\{addon}.pbo";

if (!([System.IO.File]::Exists("{build_path}\@esm\addons\{addon}.pbo"))) {{
    "Failed to build - {build_path}\@esm\addons\{addon}.pbo does not exist"
}}
"#,
                    build_path = builder.remote_build_path_str(),
                )
            }
        };

        System::new()
            .script(script)
            .add_error_detection("ErrorId")
            .add_error_detection("Failed to build")
            .add_error_detection("missing file")
            .execute_remote(&builder.build_server)?;
    }

    Ok(())
}

pub fn compile_mod(builder: &mut Builder) -> BuildResult {
    lazy_static! {
        static ref DIRECTORIES: Vec<&'static str> = vec!["optionals", "sql"];
        static ref FILES: Vec<&'static str> = vec!["Licenses.txt"];
    }

    // Set up all the paths needed
    let source_path = builder
        .local_git_path
        .join("src")
        .join("@esm")
        .join("addons");

    let mod_build_path = builder.local_build_path.join("@esm");
    let addon_destination_path = mod_build_path.join("addons");

    let mut compiler = Compiler::new();
    compiler
        .source(&source_path.to_string_lossy())
        .destination(&addon_destination_path.to_string_lossy())
        .target(&builder.args.build_os().to_string());

    crate::compile::bind_replacements(&mut compiler);
    compiler.compile()?;

    Directory::transfer(
        builder,
        mod_build_path,
        builder.remote_build_path().to_owned(),
    )?;

    Ok(())
}

pub fn build_extension(builder: &mut Builder) -> BuildResult {
    // This will be read by the build script and inserted into the extension
    let extension_path = builder.local_git_path.join("src").join("arma");
    let message_path = builder.local_git_path.join("src").join("message");

    fs::write(
        extension_path
            .join(".build-sha")
            .to_string_lossy()
            .to_string(),
        git_sha_short().as_bytes(),
    )?;

    // Copy the extension and message code over to the remote host
    Directory::transfer(
        builder,
        extension_path,
        builder.remote_build_path().to_owned(),
    )?;
    Directory::transfer(
        builder,
        message_path,
        builder.remote_build_path().to_owned(),
    )?;

    let script = match builder.args.build_os() {
        BuildOS::Windows => {
            format!(
                r#"
                        cd '{build_path}\arma';
                        rustup run stable-{build_target} cargo build --target {build_target} --release;

                        Copy-Item "{build_path}\arma\target\{build_target}\release\esm_arma.dll" -Destination "{build_path}\@esm\{file_name}.dll"
                    "#,
                build_path = builder.remote_build_path_str(),
                build_target = builder.extension_build_target,
                file_name = match builder.args.build_arch() {
                    BuildArch::X32 => "esm",
                    BuildArch::X64 => "esm_x64",
                }
            )
        }
        BuildOS::Linux => {
            format!(
                r#"
cd {build_path}/arma;
rustup run stable-{build_target} cargo build --target {build_target} --release;

cp "{build_path}/arma/target/{build_target}/release/libesm_arma.so" "{build_path}/@esm/{file_name}.so"
"#,
                build_path = builder.remote_build_path_str(),
                build_target = builder.extension_build_target,
                file_name = match builder.args.build_arch() {
                    BuildArch::X32 => "esm",
                    BuildArch::X64 => "esm_x64",
                }
            )
        }
    };

    System::new()
        .script(script)
        .add_error_detection(r"error: .+")
        .add_detection(r"warning")
        .execute_remote(&builder.build_server)?;

    Ok(())
}

pub fn seed_database(builder: &mut Builder) -> BuildResult {
    let sql = Database::generate_sql(&builder.config);
    match builder.build_server.send(Command::Database(sql)) {
        Ok(_) => Ok(()),
        Err(e) => Err(e),
    }
}

pub fn start_a3_server(builder: &mut Builder) -> BuildResult {
    match builder.args.build_os() {
        BuildOS::Windows => {
            let script = format!(
                r#"
                        Remove-Item -Path "{server_path}\@esm" -Recurse;
                        Copy-Item -Path "{build_path}\@esm" -Destination "{server_path}\@esm" -Recurse;

                        Start-Process "{server_path}\{server_executable}" `
                            -ArgumentList "{server_args}" `
                            -WorkingDirectory "{server_path}";
                    "#,
                build_path = builder.remote_build_path_str(),
                server_path = builder.remote.server_path,
                server_executable = builder.server_executable,
                server_args = builder.remote.server_args
            );

            System::new()
                .script(script)
                .execute_remote(&builder.build_server)?;
        }
        BuildOS::Linux => todo!(),
    }

    Ok(())
}

// pub fn start_a3_client(build: &mut Builder) -> BuildResult {
//     // client arg: client start args
//     // Send command to receiver
//     // Issue! In order to start the client on linux, both the linux machine and windows machine will need to be connected
//     //          This will need to be solved.
//     Ok(())
// }

pub fn stream_logs(builder: &mut Builder) -> BuildResult {
    builder.build_server.send(Command::LogStreamInit)?;

    loop {
        let result = builder.build_server.send(Command::LogStreamRequest)?;
        let lines = match result {
            Command::LogStream(l) => l,
            c => {
                return Err(
                    format!("Invalid response to LogStreamRequest. Received {:?}", c).into(),
                )
            }
        };

        for line in lines {
            let content = line.content.trim_end();
            let extension = Path::new(&line.filename)
                .extension()
                .unwrap()
                .to_string_lossy()
                .to_string();

            let highlight = HIGHLIGHTS.iter().find(|h| h.regex.is_match(content));

            println!(
                "{name}:{line_number:5}{sep} {content}",
                sep = "|".bright_black(),
                name = extension.truecolor(line.color[0], line.color[1], line.color[2]),
                line_number = line.line_number.to_string().bright_black(),
                content = if let Some(h) = highlight {
                    content.bold().truecolor(h.color[0], h.color[1], h.color[2])
                } else {
                    content.normal()
                }
            )
        }
    }
}
