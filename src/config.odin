package main

import "core:os"
import "core:fmt"
import "core:strings"
import "base:runtime"
import lua "vendor:lua/5.4"

import l "logger"
import m "models"
import u "utils"

cfg: ^m.Config

config_hook :: proc(config: ^m.Config, args: ^m.Args) {
    L: ^lua.State
    L = lua.L_newstate()
    lua.L_openlibs(L) // add standard libs to lua script
    
    register_api(L)

    cfg = config

    lua.L_dofile(L, strings.clone_to_cstring(args.script_path))

    if !u.lua_require_function(L, "create_config") {
        l.fatal(.CONFIG, fmt.tprintf("Cannot find a function called 'create_config' in %s. Abort", args.script_path))
        os.exit(1)
    }

    // put the Args on the lua stack as a table
    u.lua_pass_args(L, args)

    // Call the function and pass the args table as argument
    // 1 arguments, 0 return values
    if lua.pcall(L, 1, 0, 0) != 0 {
        err_msg := lua.tostring(L, -1)
        l.error(.CONFIG, strings.clone_from_cstring(err_msg))
        fmt.println("Lua err: ", err_msg)
    }
}

print_config :: proc(cfg: ^m.Config) {
    u.table("| Config",
        {"version_repo", cfg.version_repo},
        {"folder_project", cfg.folder_project},
        {"folder_project_abs", cfg.folder_project_abs},
        {"godot_version", cfg.godot_version},
        {"repo_url", cfg.repo_url},
        {"repo_branch", cfg.repo_branch},
        {"repo_commit", cfg.repo_commit},
        {"godot_preprocessor", cfg.godot_preprocessor},
    )
}

@(private = "file")
register_api :: proc(L: ^lua.State) {
    lua.register(L, "version_repo", lua_set_version_repo)
    lua.register(L, "project_folder", lua_set_folder_project)
    lua.register(L, "godot_version", lua_set_godot_version)
    lua.register(L, "project_repo_url", lua_set_repo_url)
    lua.register(L, "project_repo_branch", lua_set_repo_branch)
    lua.register(L, "project_repo_commit", lua_set_repo_commit)
    lua.register(L, "godot_preprocessor", lua_set_preprocessor)
}

lua_set_version_repo :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    if s, ok := u.get_string(L, 1); ok {
        cfg.version_repo = s
    }
    return 0
}

lua_set_folder_project :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    if s, ok := u.get_string(L, 1); ok {
        cfg.folder_project = s
        folder_project_abs, abs_ok := u.get_absolute_path(cfg.folder_project)
        if !abs_ok {
            l.fatal(.CONFIG, fmt.tprintf("Cannot create absolute path for folder_project: %s", cfg.folder_project))
        }
        cfg.folder_project_abs = folder_project_abs
    }
    return 0
}

lua_set_godot_version :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    if s, ok := u.get_string(L, 1); ok {
        cfg.godot_version = s
    }
    return 0
}

lua_set_repo_url :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    if s, ok := u.get_string(L, 1); ok {
        cfg.repo_url = s
    }
    return 0
}

lua_set_repo_branch :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    if s, ok := u.get_string(L, 1); ok {
        cfg.repo_branch = s
    }
    return 0
}

lua_set_repo_commit :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    if s, ok := u.get_string(L, 1); ok {
        cfg.repo_commit = s
    }
    return 0
}

lua_set_preprocessor :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    if s, ok := u.get_string(L, 1); ok {
        cfg.godot_preprocessor = s
    }
    return 0
}
