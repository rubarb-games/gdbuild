package main

import "core:os"
import "core:fmt"
import "core:strings"
import "logger"
import "base:runtime"
import lua "vendor:lua/5.4"

import "models"

config_hook :: proc(args: ^models.Args) -> [dynamic]models.Config {
    L: ^lua.State
    L = lua.L_newstate()

    lua.L_openlibs(L) // add standard libs to lua script

    register_api(L)

    lua.L_dofile(L, strings.clone_to_cstring(args.script))

    // Call create_config on lua script
    // --------------------------------
    
    lua.getglobal(L, "create_config")
    if !lua.isfunction(L, -1) {
        lua.pop(L, 1)
        lua.close(L)
        logger.fatal(.CONFIG, fmt.tprintf("No 'create_config' function found in %s. Cannot continue.", args.script))
        os.exit(1)
    }

    // make local copy so that a pointer can be passed. This is not
    // otherwise possible when working with procedure parameters
    arg_local := args

    // call pushlight.. function once for every pointer passed to lua
    lua.pushlightuserdata(L, rawptr(arg_local))

    // Update the second param to reflect the number of pointers passed
    if lua.pcall(L, 1, 1, 0) != 0 {
        err_msg := lua.tostring(L, -1)
        logger.error(.SCRIPT, strings.clone_from_cstring(err_msg))
        lua.pop(L, 1)
    }

    // Get the return value from create_config
    // ---------------------------------------

    if !lua.istable(L, -1) {
        logger.error(.SCRIPT, fmt.tprintf("Expected a table, got %s. Cannot continue.", lua.typename(L, lua.type(L, -1))))
        os.exit(1)
    }

    configs: [dynamic]models.Config

    // lua.next reads the key at the top of the stack, pops it, 
    // and pushes the next key-value pair. We start with nil (0).
    lua.pushnil(L) 
    for lua.next(L, -2) != 0 {
        // Stack state now: [-1] = value (sub-table), [-2] = key (index), [-3] = main table
        if lua.istable(L, -1) {
            cfg: models.Config
            set_default_config(&cfg)

            cfg.folder_project = get_string_field(L, "folder_project")
            cfg.godot_version = get_string_field(L, "godot_version")
            cfg.repo_url = get_string_field(L, "repo_url")
            
            cfg.folder_output = get_string_field(L, "folder_output")
            cfg.repo_branch = get_string_field(L, "repo_branch")
            cfg.repo_commit = get_string_field(L, "repo_commit")
            cfg.preprocessor = get_string_field(L, "preprocessor")
            cfg.path_log_build = get_string_field(L, "path_log_build")
            cfg.path_log_preprocessor = get_string_field(L, "path_log_preprocessor")
            cfg.path_log_export = get_string_field(L, "path_log_export")
            cfg.path_log_deployment = get_string_field(L, "path_log_deployment")

            if config_is_valid(&cfg) {
                logger.info(.CONFIG, fmt.tprint("valid"))
                append(&configs, cfg)
            }
        }
        
        lua.pop(L, 1) 
    }

	return configs
}

config_is_valid :: proc(cfg: ^models.Config) -> bool {
    if cfg.folder_project == "" do return false
    if cfg.godot_version == "" do return false
    if cfg.repo_url == "" do return false
    return true
}

@(private = "file")
get_string_field :: proc(L: ^lua.State, field_name: cstring) -> string {
    lua.getfield(L, -1, field_name)
    lua_str := lua.tostring(L, -1)
    lua.pop(L, 1)
    return strings.clone_from_cstring(lua_str)
}

@(private = "file")
set_default_config :: proc(cfg: ^models.Config) {
	cfg.repo_branch = "main"
	cfg.folder_output = "output"
	cfg.path_log_build = "logs/log_build.log"
	cfg.path_log_preprocessor = "logs/log_preprocessor.log"
	cfg.path_log_export = "logs/log_export.log"
	cfg.path_log_deployment = "logs/log_deployment.log"
}

@(private = "file")
register_api :: proc(L: ^lua.State) {
    lua.register(L, "get_version", lua_get_version)
    lua.register(L, "is_dry", lua_is_dry)
    lua.register(L, "is_verbose", lua_is_verbose)
}

// Note about the lua callbacks:
// - the lua.touserdata function expects to find a pointer to args at 
//   position 1 in the light user data table. When passing multiple
//   pointer, ensure the getters point to the correct objects.

lua_get_version :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    args := (^models.Args)(lua.touserdata(L, 1))
    if args == nil do return 0
    
    c_str := strings.clone_to_cstring(args.version)
    defer delete(c_str)
    lua.pushlstring(L, c_str, len(c_str))
    return 1
}

// lua_get_int :: proc "c" (L: ^lua.State) -> i32 {
//     args := (^models.Args)(lua.touserdata(L, 1))
//     if args == nil do return 0
    
//    lua.push(L, lua.Integer(args.something))
//    return 1
// }

lua_is_dry :: proc "c" (L: ^lua.State) -> i32 {
    ptr := (^models.Args)(lua.touserdata(L, 1))
    if ptr == nil do return 0

    lua.pushboolean(L, b32(ptr.dry))
    return 1
}

lua_is_verbose :: proc "c" (L: ^lua.State) -> i32 {
    ptr := (^models.Args)(lua.touserdata(L, 1))
    if ptr == nil do return 0

    lua.pushboolean(L, b32(ptr.verbose))
    return 1
}

// 3. Callback to get a String Array field (Returned as a Lua Table)
// get_entity_tags :: proc "c" (L: ^lua.State) -> i32 {
//     ptr := (^Entity)(lua.touserdata(L, 1))
//     if ptr == nil do return 0

//     // Create a new empty Lua table on the stack
//     lua.createtable(L, i32(len(ptr.tags)), 0)

//     for item, index in ptr.tags {
//         // Lua arrays are 1-indexed
//         lua.pushinteger(L, lua.Integer(index + 1))
//         lua.pushlstring(L, rawdata(item), len(item))
        
//         // Sets table[index + 1] = item, pops key and value off the stack
//         lua.settable(L, -3) 
//     }

//     return 1 // Returns the completed table
// }
