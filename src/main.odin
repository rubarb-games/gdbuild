package main

import "core:fmt"

import l "logger"
import m "models"
import ep "export_preset"

main :: proc() {
    fmt.println("== gdbuild ========================================================")

    args := m.Args {
        script_path = "./scripts/main.lua",
        version = "0.0",
        verbose = false,
        live = false
    }

    parse_args(&args)
    validate_args(&args)
    print_args(&args)

    if args.verbose {
        l.set_log_level(.TRACE)
    }

    cfg := m.Config {
        repo_branch = "main",
        folder_project = "project",
    }

    config_hook(&cfg, &args)
    print_config(&cfg)

    // * checkout version repo
    // * get and verify the version files
    // * get version from args
    // * bump build num
    // > lua.after_version_updated() [optional] - could be used for custom handling of versioning strategy
    // * print config and version info

    version: m.Version
    // Temporary, accept a full version string from args, break it down to components
    if args.version != "0.0" { // is not default value
        parse_version_string(&version, args.version)
    }
    print_version(&version)

    // * make directories
    // * download editor
    // * download eport templates
    // * checkout main repo
    // > lua.after_repo_checkout() [optional]
    // * preprocess
    // * reimport assets
    // > lua.create_export_preset
    // * export project
    // > lua.after_project_export() [optional]
    // * update version repo
    // * archive build
    // for each deployment target
    // * init target
    // * deploy

    // maybe a deployment target could be a lua script? makes it easy to add new ones
    // archiving needs some config. directory, naming convention, zip or not, upload?

    exp_options := m.ExportPresetOptions {}
    exp_preset := m.ExportPreset {
        options = &exp_options
    }

    ep.set_defaults(&exp_preset)
    ep.hook(&exp_preset, &args, &cfg, &version)
}

