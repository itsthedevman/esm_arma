use common::write_lock;
use compiler::Compiler;
use parking_lot::RwLock;
use serde::{Deserialize, Serialize};
use std::io::{self, Write};
use std::path::{Path, PathBuf};
use std::sync::atomic::Ordering;
use std::time::Duration;

use crate::database::Database;
use crate::Directory;
use crate::{
    read_lock, BuildArch, BuildEnv, BuildError, BuildOS, BuildResult, Command, Commands, LogLevel,
    System,
};

use colored::*;
use lazy_static::lazy_static;
use regex::Regex;
use run_script::ScriptOptions;
use std::{fs, thread};

/// Used with the test suite, this key holds the server's current esm.key
const REDIS_SERVER_KEY: &str = "test_server_key";

pub struct Remote {
    pub build_path: PathBuf,
    pub build_path_str: String,
    pub server_path: String,
    pub server_args: String,
}

impl Remote {
    #[allow(clippy::new_without_default)]
    pub fn new() -> Self {
        Remote {
            build_path: Path::new("/").to_path_buf(),
            build_path_str: "/".into(),
            server_path: String::new(),
            server_args: String::new(),
        }
    }
}

pub struct Builder {
    pub redis: redis::Client,
    /// For storing remote paths and other data
    pub remote: Remote,
    /// The OS to build the extension on
    pub os: BuildOS,
    /// 32 bit or 64 bit
    pub arch: BuildArch,
    /// The environment the extension is built for
    pub env: BuildEnv,
    /// Controls how detailed the logs are
    pub log_level: LogLevel,
    /// The host URI that is currently hosting a bot instance.
    pub bot_host: String,
    /// The path to this repo's root directory
    pub local_git_path: PathBuf,
    /// Rust's build directory
    pub local_build_path: PathBuf,
    /// Rust build target for the build OS
    pub extension_build_target: String,
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

        // Have to remove the first slash in order for this to work
        let local_git_path = std::env::current_dir()?;

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

        let local_build_path = local_git_path.join("target");

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
            redis: redis::Client::open("redis://127.0.0.1/0")?,
        };

        Ok(builder)
    }

    pub fn start(&mut self) -> BuildResult {
        self.print_status("Preparing build host", Builder::start_server)?;
        self.print_status("Waiting for build receiver", Builder::wait_for_receiver)?;

        self.print_info();
        self.print_status("Killing Arma", Builder::kill_arma)?;
        self.print_status("Cleaning directories", Builder::clean_directories)?;

        self.print_status("Preparing to build", Builder::prepare_to_build)?;

        if matches!(self.os, BuildOS::Windows) {
            self.print_status("Checking for p drive", Builder::check_for_p_drive)?;
        }

        self.print_status("Compiling @esm", Builder::compile_mod)?;
        self.print_status("Compiling esm_arma", Builder::build_extension)?;
        self.print_status("Building @esm", Builder::build_mod)?;
        self.print_status("Seeding database", Builder::seed_database)?;
        self.print_status("Starting a3 server", Builder::start_a3_server)?;
        self.print_status("Starting log stream", Builder::stream_logs)?;
        // self.print_status("Starting a3 client", Builder::start_a3_client)?; // If flag is set
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
            self.local_git_path.to_string_lossy(),
            "build directory".black().bold(),
            self.remote_build_path_str()
        )
    }

    pub fn send_to_receiver(&mut self, command: Command) -> Result<Command, BuildError> {
        let result = RwLock::new(None);
        write_lock(&crate::SERVER, |mut server| {
            *result.write() = Some(server.send(command.to_owned()));
            Ok(true)
        })?;

        if result.write().is_none() {
            return Err("Failed to send".to_string().into());
        }

        let mut writer = result.write();
        writer.take().unwrap()
    }

    fn start_server(&mut self) -> BuildResult {
        if let Err(e) = self.redis.get_connection() {
            return Err(format!("Redis server - {}", e).into());
        }

        write_lock(&crate::SERVER, |mut server| {
            server.start()?;
            Ok(true)
        })
    }

    fn wait_for_receiver(&mut self) -> BuildResult {
        read_lock(&crate::SERVER, |server| {
            if !server.connected.load(Ordering::SeqCst) {
                std::thread::sleep(Duration::from_secs(1));
                return Ok(false);
            }

            Ok(true)
        })?;

        // We're connected, request update
        match self.send_to_receiver(Command::PostInitRequest) {
            Ok(ref res) => {
                if let Command::PostInit(post_init) = res {
                    let path = post_init.build_path.to_owned();

                    self.remote = Remote {
                        build_path: Path::new(&path).to_path_buf(),
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

    pub fn system_command(&mut self, command: &mut System) -> Result<Command, BuildError> {
        lazy_static! {
            static ref WHITESPACE_REGEX: Regex = Regex::new(r"\t|\s+").unwrap();
        }

        match self.os {
            BuildOS::Windows => {
                let command_file_path = self.local_build_path.join(".esm-build-command");
                let command_result_path = self.local_build_path.join(".esm-build-command-result");

                // Removes the "Preparing modules for first use." errors that powershell return
                let script = format!(
                    "$ProgressPreference = 'SilentlyContinue'; {} {}",
                    command.command,
                    command.arguments.join(" ")
                );

                let script = WHITESPACE_REGEX.replace_all(&script, " ");
                fs::write(&command_file_path, script.as_bytes())?;

                // Convert the command file into UTF-16LE as required by Microsoft
                local_command(
                    "iconv",
                    vec![
                        "-t UTF-16LE",
                        &format!("--output={}", command_result_path.display()),
                        &command_file_path.to_string_lossy(),
                    ],
                )?;

                // To avoid dealing with UTF in rust - just have linux convert it to base64
                let mut encoded_command =
                    local_command("base64", vec![&command_result_path.to_string_lossy()])?;

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

    pub fn remote_build_path(&self) -> &PathBuf {
        &self.remote.build_path
    }

    pub fn remote_build_path_str(&self) -> &str {
        &self.remote.build_path_str
    }

    //////////////////////////////////////////////////////////////////
    /// Build steps below
    //////////////////////////////////////////////////////////////////
    fn kill_arma(&mut self) -> BuildResult {
        self.send_to_receiver(Command::KillArma)?;
        Ok(())
    }

    fn clean_directories(&mut self) -> BuildResult {
        // Local directories
        let esm_path = self.local_build_path.join("@esm");

        // Delete @esm and recreate it
        fs::remove_dir_all(&esm_path)?;
        fs::create_dir_all(&esm_path)?;

        // Create @esm/addons
        fs::create_dir_all(&esm_path.join("addons"))?;

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
                        Remove-Item "{server_path}\@esm\log\*.log";
                        Remove-Item "{server_path}\{profile_name}\*.log";
                        Remove-Item "{server_path}\{profile_name}\*.rpt";

                        Get-ChildItem "{build_path}\@esm\*.*" -Recurse | Remove-Item -Force -Recurse;

                        if ([System.IO.Directory]::Exists("{build_path}\esm\target")) {{
                            Move-Item -Path "{build_path}\esm\target" -Destination "{build_path}";
                        }}

                        if ([System.IO.Directory]::Exists("{build_path}\esm\{os}")) {{
                            Get-ChildItem "{build_path}\esm\{os}\*.*" -Recurse | Remove-Item -Force -Recurse;
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
                    os = self.os
                )
            }
            BuildOS::Linux => todo!(),
        };

        self.system_command(System::new().command(script).wait())?;

        Ok(())
    }

    fn prepare_to_build(&mut self) -> BuildResult {
        self.transfer_mikeros_tools()?;
        self.create_server_config()?;
        self.create_esm_key_file()?;
        Ok(())
    }

    fn transfer_mikeros_tools(&mut self) -> BuildResult {
        let mikero_path = self
            .local_git_path
            .join("tools")
            .join("pbo_tools")
            .join(self.os.to_string());

        Directory::transfer(self, mikero_path, self.remote_build_path().to_owned())
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
        fs::write(
            self.local_build_path
                .join("@esm")
                .join("config.yml")
                .to_string_lossy()
                .to_string(),
            config_yaml,
        )?;

        Ok(())
    }

    fn create_esm_key_file(&mut self) -> BuildResult {
        let mut connection = self.redis.get_connection()?;
        let mut last_key_received = String::new();

        // Moved to a thread so this can happen over and over again for testing purposes
        thread::spawn(move || loop {
            let key: Option<String> = redis::cmd("GET")
                .arg(REDIS_SERVER_KEY)
                .query(&mut connection)
                .unwrap();

            if key.is_none() {
                thread::sleep(Duration::from_millis(500));
                continue;
            }

            let key = key.unwrap();
            if key == last_key_received {
                thread::sleep(Duration::from_millis(500));
                continue;
            }

            write_lock(&crate::SERVER, |mut server| {
                server.send(Command::Key(key.to_owned()))?;
                Ok(true)
            })
            .unwrap();

            last_key_received = key.to_owned();
        });

        Ok(())
    }

    fn build_extension(&mut self) -> BuildResult {
        // This will be read by the build script and inserted into the extension
        let extension_path = self.local_git_path.join("esm");
        fs::write(
            extension_path
                .join(".build-sha")
                .to_string_lossy()
                .to_string(),
            git_sha_short().as_bytes(),
        )?;

        match self.os {
            BuildOS::Windows => {
                // Copy the extension over to the remote host
                Directory::transfer(self, extension_path, self.remote_build_path().to_owned())?;

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
                        .add_detection(r"error: could not compile", true)
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
                "p_drive_mounted";
            }} else {{
                "p_drive_not_mounted";
            }}
        "#;

        let result = self.system_command(
            System::new()
                .command(script)
                .add_detection("p_drive_mounted", false),
        )?;

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
        let mod_path = self.local_git_path.join("@esm");
        let source_path = mod_path.join("addons");

        let mod_build_path = self.local_build_path.join("@esm");
        let addon_destination_path = mod_build_path.join("addons");

        Compiler::new()
            .source(&source_path.to_string_lossy().to_string())
            .destination(&addon_destination_path.to_string_lossy().to_string())
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

        Directory::transfer(self, mod_build_path, self.remote_build_path().to_owned())?;

        Ok(())
    }

    fn build_mod(&mut self) -> BuildResult {
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

        match self.os {
            BuildOS::Linux => todo!(),
            BuildOS::Windows => {
                let mut extra_addons = vec![];
                if matches!(self.env, BuildEnv::Test) {
                    extra_addons.push("esm_test");
                }

                for addon in ADDONS.iter().chain(extra_addons.iter()) {
                    // If the addons are copied over to the P drive and then PBOed there?
                    // The "root" is probably what matters here. The root needs to be P: drive
                    let script = format!(
                        r#"
                            Move-Item -Force -Path "{build_path}\@esm\addons\{addon}" -Destination P:;
                            Start-Process -Wait -NoNewWindow -FilePath "{build_path}\windows\MakePbo.exe" -ArgumentList "-P", "P:\{addon}", "{build_path}\@esm\addons\{addon}.pbo"
                        "#,
                        build_path = self.remote_build_path_str(),
                    );

                    self.system_command(
                        System::new()
                            .command(script)
                            .add_detection("Failed to build", true)
                            .add_detection("missing file", true),
                    )?;
                }
            }
        }

        Ok(())
    }

    fn seed_database(&mut self) -> BuildResult {
        let data =
            crate::data::parse_data_file(self.local_git_path.join("build").join("test_data.yml"))?;

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

                self.system_command(System::new().command(script))?;
            }
            BuildOS::Linux => todo!(),
        }

        Ok(())
    }

    // fn start_a3_client(&mut self) -> BuildResult {
    //     // client arg: client start args
    //     // Send command to receiver
    //     // Issue! In order to start the client on linux, both the linux machine and windows machine will need to be connected
    //     //          This will need to be solved.
    //     Ok(())
    // }

    fn stream_logs(&mut self) -> BuildResult {
        struct Highlight {
            pub regex: Regex,
            pub color: [u8; 3],
        }

        lazy_static! {
            static ref HIGHLIGHTS: Vec<Highlight> = vec![
                Highlight {
                    regex: Regex::new(r"(?i)error\b").unwrap(),
                    color: [153, 0, 51]
                },
                Highlight {
                    regex: Regex::new(r"(?i)warn").unwrap(),
                    color: [153, 102, 0]
                },
                Highlight {
                    regex: Regex::new(r"(?i)info").unwrap(),
                    color: [102, 204, 255]
                },
                Highlight {
                    regex: Regex::new(r"(?i)debug").unwrap(),
                    color: [51, 51, 51]
                }
            ];
        }

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
                let content = line.content.trim_end();
                let prefix = Path::new(&line.filename)
                    .extension()
                    .unwrap()
                    .to_string_lossy()
                    .to_string();

                let mut file_name = line
                    .filename
                    .to_owned()
                    .trim_end_matches(&prefix)
                    .to_string();

                if file_name.len() > 15 {
                    file_name.truncate(15);
                    file_name.push_str("..");
                }

                file_name.push_str(&prefix);

                let highlight = HIGHLIGHTS.iter().find(|h| h.regex.is_match(content));

                println!(
                    "{name:.>20}:{line_number:5}{sep} {content}",
                    sep = "|".black(),
                    name = file_name.truecolor(line.color[0], line.color[1], line.color[2]),
                    line_number = line.line_number.to_string().black(),
                    content = if let Some(h) = highlight {
                        content.bold().truecolor(h.color[0], h.color[1], h.color[2])
                    } else {
                        content.normal()
                    }
                )
            }
        }
    }
}

pub fn local_command(cmd: &str, args: Vec<&str>) -> Result<String, BuildError> {
    let options = ScriptOptions::new();
    let (code, output, error) = run_script::run(
        &format!("{} {}", cmd, args.join(" ").as_str()),
        &vec![],
        &options,
    )
    .unwrap();

    if code == 0 {
        return Ok(output);
    }

    Err(error.into())
}

fn git_sha_short() -> String {
    match local_command("git", vec!["rev-parse", "--short", "HEAD"]) {
        Ok(o) => o,
        Err(_e) => "FAILED TO RETRIEVE".into(),
    }
}
