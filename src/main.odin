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

    // Could maybe pass a regex string from lua to odin, to instruct odin of how
    // to read the version string. Not everyone follows the same convention.
    // [0-9]+(major).[0-9]+(minor).[0-9]+(buildnum)
    // Something like this to indicate what a version string look like, and what
    // each part is called

    // When passing a full version string to args, buildnum should not be bumped.
    // That will allow the build pipeline to be distributed over multiple machines.
    // One machine gets the instructions, prepares the version number, then
    // delegates to other build units.

    version: m.Version
    // Temporary, accept a full version string from args, break it down to components
    if args.version != "0.0" { // is not default value
        parse_version_string(&version, args.version)
    }
    print_version(&version)

    // checkout from git

    // pre_build hook
    // * Would make it possible to make changes that are common for all build targets
    // * make it possible to trigger a re-import of assets from lua

    // duplicate project tree, once for each target?
    // * would make it safer to make changes per target

    for build_target in build.targets {
        
        l.info(.CONFIG, fmt.tprintf("Current build target: %v", build_target.name))

        // Project Settings
        // overwrites project settings
        //   - load project settings from project folder
        //   - parse? It's only ini
        //   - expose functions for overriding and removing settings
        //   - maybe a similar api as Godot's ProjectSettings would do?
        //   set("window/fullscreen", true)
        //   local val = get_bool("section/value")
        
        // Export Preset
        // overwrites the preset
        ep.hook(build_target, &args, &cfg, &version)
        
        // pre_export hook
        // * expose a reimport_assets function to lua

        // export project

        // post_export hook
        // * get access to build dir and artifacts
        // * can add files to artifacts (like readme, whatever)
    }

    // update version repo
    // * unless a full version string was passed to args

    // for each artifact:

        // archive build
        // * if enabled

        // for each distribution target:
            // distribute
}

create_build_targets :: proc(platforms_args: string, build:^m.Build) {
    platforms_str := u.strip_whitespace(platforms_args)
    defer delete(platforms_str)

    platforms := strings.split(platforms_str, ",")
    defer delete(platforms) // no need to free each element, as split produces an
    // array of pointers into the original string

    for platform in platforms {

        exp_options := new(m.ExportPresetOptions)
        
        exp_preset := new(m.ExportPreset)
        exp_preset.options = exp_options

        build_target := new(m.BuildTarget)
        build_target.name = strings.clone(platform)
        build_target.export_preset = exp_preset

        append(&build.targets, build_target)
    }
}