package main

import "core:fmt"
import "core:strings"
import "logger"
import "base:runtime"
import lua "vendor:lua/5.4"

import "models"

config_hook :: proc(args: ^models.Args) -> ^models.Config {
    L: ^lua.State
    L = lua.L_newstate()

    lua.L_openlibs(L) // add standard libs to lua script

    cfg: ^models.Config = new(models.Config)
    set_default_config(cfg)
    defer free(cfg)

    logger.info(.CONFIG, fmt.tprint("Set default Config"))
	
    register_api(L)
    logger.info(.CONFIG, fmt.tprint("lua api"))

    lua.L_dofile(L, strings.clone_to_cstring(args.script_path))

    lua.getglobal(L, "create_config")
    if !lua.isfunction(L, -1) {
        lua.pop(L, 1)
        lua.close(L)
        logger.fatal(.CONFIG, fmt.tprintf("No 'export_preset' function found in %s. Will use default export presets", args.script_path))
    }

    // Call the function
    lua.pushlightuserdata(L, rawptr(cfg))
    if lua.pcall(L, 1, 0, 0) != 0 {
        err_msg := lua.tostring(L, -1)
        logger.error(.SCRIPT, strings.clone_from_cstring(err_msg))
        fmt.println("Lua err: ", err_msg)
        lua.pop(L, 1)
    }
    logger.info(.CONFIG, fmt.tprint("called the function"))

	return cfg
}

@(private = "file")
set_default_config :: proc(cfg: ^models.Config) {
	cfg.repo_branch = "main"
	cfg.folder_project = "project"
	cfg.folder_output = "output"
	cfg.path_log_build = {"logs", "log_build.log"}
	cfg.path_log_preprocessor = {"logs", "log_preprocessor.log"}
	cfg.path_log_export = {"logs", "log_export.log"}
	cfg.path_log_deployment = {"logs", "log_deployment.log"}
}

@(private = "file")
register_api :: proc(L: ^lua.State) {
    lua.register(L, "set_folder_project", lua_set_folder_project)
    lua.register(L, "set_folder_output", lua_set_folder_output)
    lua.register(L, "set_godot_version", lua_set_godot_version)
    lua.register(L, "set_repo_branch", lua_set_repo_branch)
    lua.register(L, "set_repo_commit", lua_set_repo_commit)
    lua.register(L, "set_preprocessor", lua_set_preprocessor)
    lua.register(L, "set_path_log_build", lua_set_path_log_build)
    lua.register(L, "set_path_log_preprocessor", lua_set_path_log_preprocessor)
    lua.register(L, "set_path_log_export", lua_set_path_log_export)
    lua.register(L, "set_path_log_deployment", lua_set_path_log_deployment)
}

lua_set_folder_project :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    c := (^models.Config)(lua.touserdata(L, 1))
    if c != nil {
        c.folder_project = to_string(L, 2)
    }
    return 0
}

lua_set_folder_output :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    c := (^models.Config)(lua.touserdata(L, 1))
    if c != nil {
        c.folder_output = to_string(L, 2)
    }
    return 0
}

lua_set_godot_version :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    c := (^models.Config)(lua.touserdata(L, 1))
    if c != nil {
        c.godot_version = to_string(L, 2)
    }
    return 0
}

lua_set_repo_branch :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    c := (^models.Config)(lua.touserdata(L, 1))
    if c != nil {
        c.repo_branch = to_string(L, 2)
    }
    return 0
}

lua_set_repo_commit :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    c := (^models.Config)(lua.touserdata(L, 1))
    if c != nil {
        c.repo_commit = to_string(L, 2)
    }
    return 0
}

lua_set_preprocessor :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    c := (^models.Config)(lua.touserdata(L, 1))
    if c != nil {
        c.preprocessor = to_string(L, 2)
    }
    return 0
}

lua_set_path_log_build :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    c := (^models.Config)(lua.touserdata(L, 1))
    if c != nil {
        c.path_log_build = to_string_arr(L, 2)^
    }
    return 0
}

lua_set_path_log_preprocessor :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    c := (^models.Config)(lua.touserdata(L, 1))
    if c != nil {
        c.path_log_preprocessor = to_string_arr(L, 2)^
    }
    return 0
}

lua_set_path_log_export :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    c := (^models.Config)(lua.touserdata(L, 1))
    if c != nil {
        c.path_log_export = to_string_arr(L, 2)^
    }
    return 0
}

lua_set_path_log_deployment :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    c := (^models.Config)(lua.touserdata(L, 1))
    if c != nil {
        c.path_log_deployment = to_string_arr(L, 2)^
    }
    return 0
}
