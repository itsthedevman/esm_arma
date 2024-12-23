use std::path::{Path, PathBuf};

use crate::*;
use common::System;

pub struct Directory;

impl Directory {
    pub fn transfer(
        builder: &mut Builder,
        source_path: PathBuf,
        destination_path: PathBuf,
    ) -> BuildResult {
        let dir_name = source_path.file_name().unwrap().to_string_lossy();
        let file_name = format!("{}.zip", dir_name);

        if System::new()
            .script(&format!(
                "cd {}; zip -r {} ./{}",
                source_path.parent().unwrap().to_string_lossy(),
                builder.local_build_path.join(&file_name).to_string_lossy(),
                dir_name
            ))
            .execute(None)
            .is_err()
        {
            return Err(format!(
                "Failed to zip {} for transfer",
                source_path.to_string_lossy()
            )
            .into());
        };

        let destination_path_str = destination_path.to_string_lossy().to_string();
        File::transfer(
            builder,
            builder.local_build_path.to_owned(),
            destination_path,
            &file_name,
        )?;

        let script = match builder.args.build_os() {
            crate::BuildOS::Linux => {
                format!("unzip -o {destination_path_str}/{file_name} -d {destination_path_str} && rm -f {destination_path_str}/{file_name}")
            }
            crate::BuildOS::Windows => {
                format!(
                    "
                        Import-Module Microsoft.PowerShell.Archive;
                        Expand-Archive -Force -Path '{destination_path_str}\\{file_name}' -DestinationPath '{destination_path_str}';
                        Remove-Item -Path '{destination_path_str}\\{file_name}';
                    "
                )
            }
        };

        System::new()
            .script(script)
            .target_os(builder.build_os())
            .execute_remote(&builder.build_server)?;
        Ok(())
    }

    pub fn copy(source: &Path, destination: &Path) -> BuildResult {
        assert!(matches!(source.is_dir(), true));

        System::new()
            .command("cp")
            .arguments(&[
                "-r",
                &source.to_string_lossy(),
                &destination.to_string_lossy(),
            ])
            .execute(None)?;

        Ok(())
    }
}
