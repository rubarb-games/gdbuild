package main

import "core:fmt"
import "core:strings"
import "core:mem"

import u "utils"
import l "logger"
import m "models"
import ep "export_preset"

main :: proc() {
    track: mem.Tracking_Allocator
    mem.tracking_allocator_init(&track, context.allocator)
    context.allocator = mem.tracking_allocator(&track)

    defer {
        // if len(track.allocation_map) > 0 {
        //     fmt.eprintf("=== %v allocations not freed: ===\n", len(track.allocation_map))
        //     for _, entry in track.allocation_map {
        //         fmt.eprintf("- %v bytes @ %v\n", entry.size, entry.location)
        //     }
        // }
        if len(track.bad_free_array) > 0 {
            fmt.eprintf("=== %v incorrect frees: ===\n", len(track.bad_free_array))
            for entry in track.bad_free_array {
                fmt.eprintf("- %p @ %v\n", entry.memory, entry.location)
            }
        }
        mem.tracking_allocator_destroy(&track)
    }

    fmt.println("== gdbuild ========================================================\n")

    // Default command line arguments
    args := m.Args {
        script_path = "./scripts/main.lua",
        version = "0.0",
        verbose = false,
        live = false
    }

    // Default config
    cfg := m.Config {
        repo_branch = "main",
    }

    build := m.Build {
        args = &args,
        config = &cfg,
        targets = [dynamic]^m.BuildTarget{},
    }

    // Command line arguments
    parse_args(&args)
    validate_args(&args)
    print_args(&args)

    if args.verbose {
        l.set_log_level(.TRACE)
    }

    create_build_targets(args.platforms, &build)

    // Prepare Config
    cfg.build_type = args.build_type
    cfg.build_mode = args.build_mode

    // Build Config
    config_hook(&cfg, &args)
    print_config(&cfg)

    // post config:
    // * make directories
    // * download editor
    // * download eport templates
    // * checkout main repo

    // * checkout version repo
    // * get and verify the version files
    // * get version from args
    // * make copy of current version
    // > lua.update_version(current) [optional]
    // * if lua callback exists, but new version is not the same as current:
    //   * ABORT. Must make a change to version
    // * if lua callback does NOT exist:
    //   * bump build num
    // * print config and version info

    version: m.Version
    // Temporary, accept a full version string from args, break it down to components
    if args.version != "0.0" { // is not default value
        parse_version_string(&version, args.version)
    }
    print_version(&version)

    // > lua.project_settings()
    //   - load project settings from project folder
    //   - parse? It's only ini
    //   - expose functions for overriding and removing settings
    //   - maybe a similar api as Godot's ProjectSettings would do?
    //   set("window/fullscreen", true)
    //   local val = get_bool("section/value")

    // for build_target in build.targets {
    //     ep.hook(build_target.export_preset, &args, &cfg, &version)
    // }

    // > lua.pre_export() [optional]
    //   use for any last minute changes to the project
    //   could perhaps have a similar hook a bit earlier


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

}

create_build_targets :: proc(platforms_args: string, build:^m.Build) {
    platforms_str := u.strip_whitespace(platforms_args)
    defer delete(platforms_str)

    platforms := strings.split(platforms_str, ",")
    // defer {
    //     for s in platforms {
    //         delete(s)
    //     }
    //     delete(platforms)
    // }

    for platform in platforms {

        platform_name := ""
        switch platform {
            case "win":       platform_name = "Windows Desktop"
            case "linux":     platform_name = "Linux"
            case "mac":       platform_name = "macOS"
            case "steamdeck": platform_name = "Linux"
        }

        exp_options := m.ExportPresetOptions {}
        exp_preset := m.ExportPreset {
            platform = platform_name,
            options = &exp_options,
        }

        build_target := m.BuildTarget {
            name = platform,
            export_preset = &exp_preset,
        }

        append(&build.targets, &build_target)
    }
}