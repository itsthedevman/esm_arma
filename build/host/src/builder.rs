use compiler::Compiler;
use serde::{Deserialize, Serialize};
use std::io::{self, Write};
use std::process::Output;
use std::sync::atomic::Ordering;
use std::time::Duration;
use vfs::{PhysicalFS, VfsPath};

use crate::database::Database;
use crate::Directory;
use crate::{
    server::Server, BuildArch, BuildEnv, BuildError, BuildOS, BuildResult, Command, Commands, File,
    LogLevel, System, SystemCommand,
};

use colored::*;
use lazy_static::lazy_static;
use regex::Regex;

lazy_static! {
    static ref ADDONS: Vec<&'static str> = vec![
        "exile_server_manager",
        "exile_server_overwrites",
        "exile_server_xm8",
        "exile_server_hacking",
        "exile_server_grinding",
        "exile_server_charge_plant_started",
        "exile_server_flag_steal_started",
        "exile_server_player_connected"
    ];
}

struct Remote {
    pub build_path: VfsPath,
    pub build_path_str: String,
    pub server_path: String,
    pub server_args: String,
}

impl Remote {
    pub fn new() -> Self {
        Remote {
            build_path: VfsPath::new(PhysicalFS::new("/")),
            build_path_str: "/".into(),
            server_path: String::new(),
            server_args: String::new(),
        }
    }
}

pub struct Builder {
    /// For sending messages
    server: Server,
    /// For storing remote paths and other data
    remote: Remote,
    /// The OS to build the extension on
    os: BuildOS,
    /// 32 bit or 64 bit
    arch: BuildArch,
    /// The environment the extension is built for
    env: BuildEnv,
    /// Controls how detailed the logs are
    log_level: LogLevel,
    /// The host URI that is currently hosting a bot instance.
    bot_host: String,
    /// The path to this repo's root directory
    local_git_path: VfsPath,
    /// Rust's build directory
    local_build_path: VfsPath,
    /// Rust build target for the build OS
    extension_build_target: String,
}

impl Builder {
    pub fn new(command: Commands) -> Result<Self, BuildError> {
        let (build_x32, os, log_level, env, bot_host) = match command {
            Commands::Run {
                build_x32,
                target,
                log_level,
                env,
                bot_host,
            } => (build_x32, target, log_level, env, bot_host),
        };

        let arch = if build_x32 {
            BuildArch::X32
        } else {
            BuildArch::X64
        };

        let root_path = VfsPath::new(PhysicalFS::new("/"));

        // Have to remove the first slash in order for this to work
        let local_git_path = root_path
            .join(&std::env::current_dir()?.to_string_lossy()[1..])
            .unwrap();

        let extension_build_target: String = match os {
            BuildOS::Windows => match arch {
                BuildArch::X32 => "i686-pc-windows-msvc".into(),
                BuildArch::X64 => "x86_64-pc-windows-msvc".into(),
            },
            BuildOS::Linux => match arch {
                BuildArch::X32 => "i686-unknown-linux-gnu".into(),
                BuildArch::X64 => "x86_64-unknown-linux-gnu".into(),
            },
        };

        let local_build_path = local_git_path.join("target")?;
        let builder = Builder {
            os,
            arch,
            env,
            bot_host,
            log_level,
            local_git_path,
            extension_build_target,
            local_build_path,
            remote: Remote::new(),
            server: Server::new(),
        };

        Ok(builder)
    }

    pub fn start(&mut self) -> BuildResult {
        self.print_status("Preparing", Builder::start_server)?;
        self.print_status("Waiting for build receiver", Builder::wait_for_receiver)?;

        if matches!(self.os, BuildOS::Windows) {
            self.print_status("Checking for p drive", Builder::check_for_p_drive)?;
        }

        self.print_info();

        self.print_status("Killing Arma", Builder::kill_arma)?;
        self.print_status("Cleaning directories", Builder::clean_directories)?;
        self.print_status("Writing server config", Builder::create_server_config)?;
        self.print_status("Compiling @esm", Builder::compile_mod)?;
        self.print_status("Compiling esm_arma", Builder::build_extension)?;

        self.print_status("Building @esm", Builder::build_mod)?;
        // self.print_status("Seeding database", Builder::seed_database)?;
        // self.print_status("Starting a3 server", Builder::start_a3_server)?;
        // self.print_status("Starting a3 client", Builder::start_a3_client)?; // If flag is set
        // self.print_status("Starting log stream", Builder::stream_logs)?;
        Ok(())
    }

    fn print_status<F>(
        &mut self,
        message: impl Into<String> + std::fmt::Display,
        code: F,
    ) -> BuildResult
    where
        F: Fn(&mut Builder) -> BuildResult,
    {
        print!("{} - {message} ... ", "<esm_bt>".blue().bold());

        // Forces print to write
        if let Err(e) = io::stdout().flush() {
            println!("{}", "failed".red().bold());
            return Err(e.to_string().into());
        }

        match code(self) {
            Ok(_) => {
                println!("{}", "done".green().bold());
                Ok(())
            }
            Err(e) => {
                println!("{}", "failed".red().bold());
                Err(e)
            }
        }
    }

    fn print_info(&self) {
        println!(
            "{} - Starting @esm build for\n  {:17}: {}\n  {:17}: {}\n  {:17}: {}\n  {:17}: {}\n  {:17}: {}\n  {:17}: {}",
            "<esm_bt>".blue().bold(),
            "os".black().bold(),
            format!("{:?}", self.os).to_lowercase(),
            "arch".black().bold(),
            format!("{:?}", self.arch).to_lowercase(),
            "env".black().bold(),
            format!("{:?}", self.env).to_lowercase(),
            "log level".black().bold(),
            format!("{:?}", self.log_level).to_lowercase(),
            "git directory".black().bold(),
            self.local_git_path.as_str(),
            "build directory".black().bold(),
            self.remote_build_path_str()
        )
    }

    pub fn teardown(&mut self) {
        self.server.stop();
    }

    fn send_to_receiver(&mut self, command: Command) -> Result<Command, BuildError> {
        self.server.send(command)
    }

    fn start_server(&mut self) -> BuildResult {
        self.server.start()
    }

    fn wait_for_receiver(&mut self) -> BuildResult {
        while !self.server.connected.load(Ordering::SeqCst) {
            std::thread::sleep(Duration::from_secs(1))
        }

        // We're connected, request update
        match self.send_to_receiver(Command::PostInitRequest) {
            Ok(ref res) => {
                if let Command::PostInit(post_init) = res {
                    let path = post_init.build_path.to_owned();

                    self.remote = Remote {
                        build_path: match self.os {
                            BuildOS::Windows => {
                                VfsPath::new(PhysicalFS::new(&path[0..=1])).join(&path[3..])?
                            }
                            BuildOS::Linux => {
                                VfsPath::new(PhysicalFS::new("/")).join(&path[1..])?
                            }
                        },
                        build_path_str: path,
                        server_path: post_init.server_path.to_owned(),
                        server_args: post_init.server_args.to_owned(),
                    }
                } else {
                    return Err("Invalid response from receiver".to_string().into());
                }
            }
            Err(e) => return Err(e),
        };

        Ok(())
    }

    fn system_command(&mut self, command: &mut System) -> Result<Command, BuildError> {
        lazy_static! {
            static ref WHITESPACE_REGEX: Regex = Regex::new(r"\t|\s+").unwrap();
        }

        match self.os {
            BuildOS::Windows => {
                let command_file_path = self.local_build_path.join(".esm-build-command").unwrap();
                let command_result_path =
                    self.local_build_path.join(".esm-build-command-result")?;

                // Removes the "Preparing modules for first use." errors that powershell return
                let script = format!(
                    "$ProgressPreference = 'SilentlyContinue'; {} {}",
                    command.command,
                    command.arguments.join(" ")
                );

                let script = WHITESPACE_REGEX.replace_all(&script, " ");
                command_file_path
                    .create_file()?
                    .write_all(script.as_bytes())?;

                // Convert the command file into UTF-16LE as required by Microsoft
                local_command(
                    "iconv",
                    vec![
                        "-t UTF-16LE",
                        &format!("--output={}", command_result_path.as_str()),
                        command_file_path.as_str(),
                    ],
                )?;

                // To avoid dealing with UTF in rust - just have linux convert it to base64
                let base64_output = local_command("base64", vec![command_result_path.as_str()])?;

                let mut encoded_command =
                    String::from_utf8_lossy(&base64_output.stdout).to_string();

                // Remove the trailing newline
                encoded_command.pop();

                command.command("powershell");
                command.arguments(vec!["-EncodedCommand".to_string(), encoded_command]);

                // Finally send the command to powershell
                self.send_to_receiver(Command::System(command.to_owned()))
            }
            BuildOS::Linux => self.send_to_receiver(Command::System(command.to_owned())),
        }
    }

    fn remote_build_path(&self) -> &VfsPath {
        &self.remote.build_path
    }

    fn remote_build_path_str(&self) -> &str {
        &self.remote.build_path_str
    }

    //////////////////////////////////////////////////////////////////
    /// Build steps below
    //////////////////////////////////////////////////////////////////
    fn kill_arma(&mut self) -> BuildResult {
        lazy_static! {
            // Stop-Process doesn't want the extension
            static ref WINDOWS_EXES: &'static [&'static str] = &[
                "arma3server",
                "arma3server_x64",
                "arma3_x64",
                "arma3",
                "arma3battleye"
            ];
            static ref LINUX_EXES: &'static [&'static str] = &["arma3server", "arma3server_x64"];
        };

        let mut script = String::new();
        match self.os {
            BuildOS::Windows => {
                for exe in WINDOWS_EXES.iter() {
                    script.push_str(&format!("Stop-Process -Name {exe};"));
                }
            }
            BuildOS::Linux => {
                for exe in LINUX_EXES.iter() {
                    script.push_str(&format!("pkill {exe};"));
                }
            }
        }

        self.system_command(System::new().command(script))?;
        Ok(())
    }

    fn clean_directories(&mut self) -> BuildResult {
        // Local directories
        let esm_path = self.local_build_path.join("@esm")?;

        // Delete @esm and recreate it
        esm_path.remove_dir_all()?;
        esm_path.create_dir_all()?;

        // Create @esm/addons
        esm_path.join("addons")?.create_dir_all()?;

        /////////////////////
        // Remote directories
        let script = match self.os {
            BuildOS::Windows => {
                lazy_static! {
                    static ref PROFILES_REGEX: Regex = Regex::new(r#"-profiles=(\w+)"#).unwrap();
                };

                let captures = PROFILES_REGEX.captures(&self.remote.server_args).unwrap();
                let profile_name = match captures.get(1) {
                    Some(n) => n.as_str(),
                    None => return Err(
                        "\"-profiles\" must be provided in the server args. This is required for log streaming"
                            .to_string()
                            .into(),
                    ),
                };

                format!(
                    r#"
                        Remove-Item "{server_path}\{profile_name}\*.log";
                        Remove-Item "{server_path}\{profile_name}\*.rpt";

                        Get-ChildItem "{build_path}\@esm\*.*" -Recurse | Remove-Item -Force -Recurse;

                        if ([System.IO.Directory]::Exists("{build_path}\esm\target")) {{
                            Move-Item -Path "{build_path}\esm\target" -Destination "{build_path}";
                        }}

                        Get-ChildItem "{build_path}\esm\*.*" -Recurse | Remove-Item -Force -Recurse;

                        $Dirs = "{build_path}\esm",
                                "{build_path}\@esm",
                                "{build_path}\@esm\addons";

                        Foreach ($dir in $Dirs) {{
                            if (![System.IO.Directory]::Exists($dir)) {{
                                New-Item -Path $dir -ItemType Directory;
                            }}
                        }};

                        if ([System.IO.Directory]::Exists("{build_path}\target")) {{
                            Move-Item -Path "{build_path}\target" -Destination "{build_path}\esm\target";
                        }}
                    "#,
                    build_path = self.remote_build_path_str(),
                    server_path = self.remote.server_path,
                    profile_name = profile_name,
                )
            }
            BuildOS::Linux => todo!(),
        };

        self.system_command(System::new().command(script).wait())?;
        Ok(())
    }

    fn create_server_config(&mut self) -> BuildResult {
        #[derive(Debug, PartialEq, Serialize, Deserialize)]
        struct Config {
            connection_url: String,
            log_level: String,
            env: String,
        }

        let config = Config {
            connection_url: self.bot_host.clone(),
            log_level: self.log_level.to_string(),
            env: self.env.to_string(),
        };

        let config_yaml = serde_yaml::to_vec(&config)?;
        self.local_build_path
            .join("@esm")?
            .join("config.yml")?
            .create_file()?
            .write_all(&config_yaml)?;

        Ok(())
    }

    fn build_extension(&mut self) -> BuildResult {
        // This will be read by the build script and inserted into the extension
        let extension_path = self.local_git_path.join("esm")?;
        extension_path
            .join(".build-sha")?
            .create_file()?
            .write_all(&git_sha_short())?;

        match self.os {
            BuildOS::Windows => {
                // Copy the extension over to the remote host
                let destination = self.remote_build_path().to_owned();
                Directory::transfer(&mut self.server, extension_path, destination)?;

                let script = format!(
                    r#"
                        cd '{build_path}\esm';
                        rustup run stable-{build_target} cargo build --target {build_target} --release;

                        Copy-Item "{build_path}\esm\target\{build_target}\release\esm_arma.dll" -Destination "{build_path}\@esm\{file_name}.dll"
                    "#,
                    build_path = self.remote_build_path_str(),
                    build_target = self.extension_build_target,
                    file_name = match self.arch {
                        BuildArch::X32 => "esm",
                        BuildArch::X64 => "esm_x64",
                    }
                );

                self.system_command(
                    System::new()
                        .command(script)
                        .add_detection(r"error", true)
                        .add_detection(r"warning", false),
                )?;
            }
            BuildOS::Linux => todo!(),
        }

        Ok(())
    }

    fn check_for_p_drive(&mut self) -> BuildResult {
        assert!(matches!(self.os, BuildOS::Windows));

        let script = r#"
            if (Get-PSDrive P -ErrorAction SilentlyContinue) {{
                "p_drive_not_mounted";
            }} else {{
                "p_drive_mounted";
            }}
        "#;

        let result = self.system_command(System::new().command(script).with_stdout())?;

        // Continue building
        if let Command::SystemResponse(r) = result {
            if r == *"p_drive_mounted" {
                return Ok(());
            }
        } else {
            panic!("Invalid response for System command. Must be Command::SystemResponse");
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
            build_path = self.remote_build_path_str(),
        );

        self.system_command(
            System::new()
                .command(script)
                .wait()
                .add_detection("p_drive_not_mounted", true),
        )?;
        Ok(())
    }

    fn compile_mod(&mut self) -> BuildResult {
        lazy_static! {
            static ref DIRECTORIES: Vec<&'static str> = vec!["optionals", "sql"];
            static ref FILES: Vec<&'static str> = vec!["Licenses.txt"];
        }

        // Set up all the paths needed
        let mod_path = self.local_git_path.join("@esm")?;
        let source_path = mod_path.join("addons")?;

        let mod_build_path = self.local_build_path.join("@esm")?;
        let addon_destination_path = mod_build_path.join("addons")?;

        Compiler::new()
            .source(source_path.as_str())
            .destination(addon_destination_path.as_str())
            .target(&self.os.to_string())
            .replace(r#"compiler\.os\.path\((.+,?)\)"#, |compiler, matches| {
                let path_chunks: Vec<String> = matches
                    .get(1)
                    .unwrap()
                    .as_str()
                    .split(',')
                    .map(|p| p.trim().replace('"', ""))
                    .collect();

                let separator = if let compiler::Target::Windows = compiler.target {
                    "\\"
                } else {
                    "/"
                };

                // Windows: \my_addon\path
                // Linux: /my_addon/path
                Some(format!("\"{}{}\"", separator, path_chunks.join(separator)))
            })
            .compile()?;

        let destination = self.remote_build_path().to_owned();
        Directory::transfer(&mut self.server, mod_build_path, destination)?;

        Ok(())
    }

    fn build_mod(&mut self) -> BuildResult {
        let mikero_path = self
            .local_git_path
            .join("tools")?
            .join("pbo_tools")?
            .join(self.os.to_string())?;

        let destination = self.remote_build_path().to_owned();
        Directory::transfer(&mut self.server, mikero_path, destination)?;

        match self.os {
            BuildOS::Linux => todo!(),
            BuildOS::Windows => {
                for addon in ADDONS.iter() {
                    todo!();
                    // let script = format!(
                    //     r#"
                    //         $AddonNames = Get-ChildItem -Path "{build_path}" -Name -Directory -Depth 0;
                    //         Foreach ($name in $AddonNames) {{
                    //             Start-Process -Wait -FilePath "{build_path}\windows\MakePbo.exe" -ArgumentList "{build_path}\@esm\addons\$name", "{build_path}\@esm\addons\$name.pbo";

                    //             if ($?) {{
                    //                 Get-ChildItem "{build_path}\@esm\addons\$name" | Remove-Item -Force -Recurse;
                    //             }}
                    //         }}

                    //         echo "esm.build.done";
                    //     "#,
                    //     build_path = self.remote_build_path_str(),
                    // );
                }

                // self.system_command(System {
                //     cmd: script,
                //     args: vec![],
                //     check_for_success: true,
                //     success_regex: r#"esm\.build\.done"#.into(),
                // })?;
            }
        }

        // // Create the PBOs
        // for addon in ADDONS.iter() {
        //     let result = SystemCommand::new(mikero_path.join("bin")?.join("makepbo")?.as_str())
        //         .env("LD_LIBRARY_PATH", mikero_path.join("lib")?.as_str())
        //         .args(vec![
        //             &format!("{}/{addon}", source_path.as_str()),
        //             &format!("{}/{addon}.pbo", addon_destination_path.as_str()),
        //         ])
        //         .output()?;

        //     if !result.status.success() {
        //         let output = format!(
        //             "Failed to build {addon}.pbo\n{}\n{}\n\n{}\n{}",
        //             "stdout".green().bold(),
        //             String::from_utf8_lossy(&result.stdout).black(),
        //             "stderr".red().bold(),
        //             String::from_utf8_lossy(&result.stderr).red()
        //         );

        //         return Err(output.into());
        //     }
        // }

        // // Copy the rest of the mod contents
        // for directory in DIRECTORIES.iter() {
        //     Directory::copy(&mod_path.join(directory)?, &mod_build_path.join(directory)?)?
        // }

        // for file in FILES.iter() {
        //     File::copy(&mod_path.join(file)?, &mod_build_path.join(file)?)?
        // }
        Ok(())
    }

    fn seed_database(&mut self) -> BuildResult {
        let data = crate::data::parse_data_file(
            self.local_git_path.join("build")?.join("test_data.yml")?,
        )?;

        let sql = Database::generate_sql(data);
        match self.send_to_receiver(Command::Database(sql)) {
            Ok(_) => Ok(()),
            Err(e) => Err(e),
        }
    }

    fn start_a3_server(&mut self) -> BuildResult {
        match self.os {
            BuildOS::Windows => {
                let script = format!(
                    r#"
                        Remove-Item -Path "{server_path}\@esm" -Recurse;
                        Copy-Item -Path "{build_path}\@esm" -Destination "{server_path}\@esm" -Recurse;

                        Start-Process "{server_path}\{server_executable}" `
                            -ArgumentList "{server_args}" `
                            -WorkingDirectory "{server_path}";
                    "#,
                    build_path = self.remote_build_path_str(),
                    server_path = self.remote.server_path,
                    server_executable = match self.arch {
                        BuildArch::X32 => "arma3server.exe",
                        BuildArch::X64 => "arma3server_x64.exe",
                    },
                    server_args = self.remote.server_args
                );

                self.system_command(System::new().command(script).wait())?;
            }
            BuildOS::Linux => todo!(),
        }

        Ok(())
    }

    fn start_a3_client(&mut self) -> BuildResult {
        // client arg: client start args
        // Send command to receiver
        // Issue! In order to start the client on linux, both the linux machine and windows machine will need to be connected
        //          This will need to be solved.
        Ok(())
    }

    fn stream_logs(&mut self) -> BuildResult {
        self.send_to_receiver(Command::LogStreamInit)?;

        loop {
            let result = self.send_to_receiver(Command::LogStreamRequest)?;
            let lines = match result {
                Command::LogStream(l) => l,
                c => {
                    return Err(
                        format!("Invalid response to LogStreamRequest. Received {:?}", c).into(),
                    )
                }
            };

            for line in lines {
                println!(
                    "{name}\n{content}",
                    name = line
                        .filename
                        .truecolor(line.color[0], line.color[1], line.color[2]),
                    content = line.content.trim_end()
                )
            }
        }
    }
}

fn local_command(cmd: &str, args: Vec<&str>) -> Result<Output, BuildError> {
    match SystemCommand::new(cmd).args(args).output() {
        Ok(o) => Ok(o),
        Err(e) => Err(BuildError::Generic(e.to_string())),
    }
}

fn git_sha_short() -> Vec<u8> {
    match local_command("git", vec!["rev-parse", "--short", "HEAD"]) {
        Ok(o) => o.stdout,
        Err(_e) => "FAILED TO RETRIEVE".into(),
    }
}
