package main

import "core:fmt"

import m "models"
import ep "export_preset"
import c "config"

main :: proc() {
    fmt.println("== gdbuild ========================================================")

    args := m.Args {
        script_path = "./scripts/main.lua",
        version = "0.0",
        verbose = false,
        live = false
    }

    parse(&args)
    validate(&args)
    print(&args)

    cfg := m.Config {
        repo_branch = "main",
        folder_project = "project",
    }

    c.hook(&cfg, &args)
    c.print(&cfg)

    // * checkout version repo
    // * get and verify the version files
    // * get version from args
    // * bump build num
    // > lua.on_version_updated() [optional] - could be used for custom handling of versioning strategy
    // * print config and version info

    exp_options := m.ExportPresetOptions {}
    exp_preset := m.ExportPreset {
        options = &exp_options
    }

    ep.set_defaults(&exp_preset)
    ep.hook(&args, &cfg, &exp_preset) // also version
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

