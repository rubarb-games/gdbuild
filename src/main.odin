package main

import "core:fmt"
import "core:flags"
import "core:os"
import "core:path/filepath"
//import strings "core:strings"
import lua "vendor:lua/5.4"

import "logger"
import "models"

L: ^lua.State

main :: proc() {
    args: models.Args

    // Set default before parsing
    // The defaults could be put in a config file, to allow for customizing per project
    args.dry = true // default to a dry run to prevent accidentally distributing the build
    args.version = "0.0" // on the first run, the cache will be populated with the default version. On subsequent runs, the default version will be overridden by the version from the cache
    args.verbose = false

    script_path, join_err := filepath.join({"./scripts/", "main.lua"})
    if join_err != nil {
        logger.fatal(.CONFIG, fmt.tprintf("Cannot create file path for ./scripts/main.lua. Abort."))
        os.exit(1)
    }
    args.script_path = script_path

    err := flags.parse(&args, os.args[1:])
    if err != nil {
        logger.fatal(.CONFIG, fmt.tprintf("Error parsing arguments: %v\n", err))
        stderr_stream := os.to_stream(os.stderr)
        flags.write_usage(stderr_stream, models.Args, os.args[0])
        os.exit(1)
    }

    // do some form of validation of args?
    // - a bit hard to valiate a version number, as different apps use different schemes

    // Use a terminal printing package to prettify the output of the config building
    fmt.println("Arguments =========================================================")
    fmt.printfln("  script_path: %s", args.script_path)
    fmt.printfln("          dry: %v", args.dry)
    fmt.printfln("      version: %s", args.version)
    fmt.printfln("      verbose: %v", args.verbose)

    // Let each hook define their own Lua context. Makes it easier to isolate
    // the hook api, and keep api simple

    // create a config object
    // used for setting project root folder, preprocessor script, if any, etc.
    cfg: ^models.Config = config_hook(&args)

    logger.info(.CONFIG, fmt.tprintf("folder_project: %v", cfg.folder_project))

    export_preset_hook(&args, cfg)

//    L = lua.L_newstate()
//    lua.L_openlibs(L) // open standard libs for Lua

    //lua.register(L, "export_set_name", export_set_name)

//    lua.L_dofile(L, strings.clone_to_cstring(script_path))


//    lua.getglobal(L, "export_preset")
//    if !lua.isfunction(L, -1) {
//		lua.pop(L, 1)
//		lua.close(L)
//		logger.fatal(.CONFIG, "No export_preset function found in config.lua. Cannot continue. Or maybe?")
//	}

//    lua.pushlightuserdata(L, rawptr(&ep))
//    if lua.pcall(L, 1, 0, 0) != 0 {
//        err_msg := lua.tostring(L, -1)
//        fmt.println("Lua err: ", err_msg)
//        lua.pop(L, 1)
//    }

//    logger.info(.CONFIG, fmt.tprintf("Export Preset name: %s", ep.name))



    //lua.call(L, 0, 1) // seems to be the way to call a function that has no arguments

    // check if the lua function returned an object
    //if !lua.istable(L, -1) {
    //    lua.pop(L, -1)
    //    lua.close(L)
    //    logger.info(.CONFIG, "No config returned from script, using defaults instead.")
    //}

    //lua.getfield(L, -1, "name")
    //if lua.isstring(L, -1) {
    //    project_name: string = strings.clone_from_cstring(lua.tostring(L, -1))
    //    logger.info(.CONFIG, fmt.tprintf("Got name from lua: %s", project_name))
    //}
}

// put in export_preset package
//export_get_name :: proc "c" (L: ^lua.State) -> i32 {
    // Retrieve the rawptr (argument 1) and cast it back to a ^Player
//    player := (^Player)(lua.touserdata(L, 1))
    
//    if player != nil {
//        lua.pushinteger(L, lua.Integer(player.hp)) // Push value to Lua stack
//        return 1                                  // Returning 1 value
//    }
    
//    return 0 // Return nothing if pointer is invalid
//}

//export_set_name :: proc "c" (L: ^lua.State) -> i32 {
//    ep := (^ExportPreset)(lua.touserdata(L, 1)) // Light Userdata pointer
//    new_name := string(lua.L_checkstring(L, 2))  // Get the value

//    if ep != nil {
//        ep.name = new_name // Modify the actual memory inside Odin
//    }
    
//    return 0 // Setters don't need to return a value to Lua
//}