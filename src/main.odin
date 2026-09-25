package main

import "core:fmt"
import "core:flags"
import "core:os"
import "core:path/filepath"
import strings "core:strings"
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
    args.script = script_path

    err := flags.parse(&args, os.args[1:])
    if err != nil {
        logger.fatal(.CONFIG, fmt.tprintf("Error parsing arguments: %v\n", err))
        stderr_stream := os.to_stream(os.stderr)
        flags.write_usage(stderr_stream, models.Args, os.args[0])
        os.exit(1)
    }

    fmt.println("== Arguments =========================================================")
    table(
        {"script", args.script},
        {"dry", fmt.tprint(args.dry)},
        {"version", args.version},
        {"verbose", fmt.tprint(args.verbose)},
    )

    // create a config object
    // used for setting project root folder, preprocessor script, if any, etc.
    configs := config_hook(&args)
    defer delete(configs)

    logger.info(.CONFIG, fmt.tprintf("Got %v Config objects", len(configs)))

    // export_preset_hook(&args, cfg)
}

table :: proc(lines: ..[]string) {
    cols : [dynamic]int
    defer delete(cols)

    // set each col to 0
    for line in lines {
        for cell, i in line {
            append(&cols, 0)
        }
    }

    // find the widest cells
    for line in lines {
        for cell, i in line {
            if len(cell) > cols[i] {
                cols[i] = len(cell)
            }
        }
    }

    for line in lines {
        cells : [dynamic]string
        for cell, i in line {
            if i == 0 {
                s := strings.left_justify(cell, cols[i], " ")
                append(&cells, strings.right_justify(s, len(s) + 2, " "))
            } else {
                append(&cells, strings.left_justify(cell, cols[i], " "))
            }
        }
        res, err := strings.join(cells[:], "  ")
        if err != nil {
            logger.error(.CONFIG, "Cannot join strings")
        }
        defer delete(res)
        fmt.println(res)
    }
}

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