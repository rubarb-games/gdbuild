package utils

import "core:fmt"
import "core:os"
import "core:strings"
import "core:path/filepath"
import lua "vendor:lua/5.4"

import l "../logger"
import m "../models"

main :: proc() {}

table :: proc(title: string, lines: ..[]any) {
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
            cell_str := fmt.aprintf("%v", cell)
            if len(cell_str) > cols[i] {
                cols[i] = len(cell_str)
            }
        }
    }

    fmt.println(title)
    
    for line in lines {
        cells : [dynamic]string
        for cell, i in line {
            cell_str := fmt.aprintf("%v", cell)
            if i == 0 {
                s := strings.left_justify(cell_str, cols[i], " ")
                append(&cells, strings.right_justify(s, len(s) + 2, " "))
            } else {
                append(&cells, strings.left_justify(cell_str, cols[i], " "))
            }
        }

        res, err := strings.join(cells[:], "  ")
        if err != nil {
            fmt.eprintln("Cannot join strings")
        }
        defer delete(res)
        fmt.println(res)
    }
    
    fmt.println("")
}

walk_tree :: proc(abs_path: string, path_buffer: ^[dynamic]string) -> os.Error {
    // Open the current directory
    dir_handle, err := os.open(abs_path)
    if err != os.ERROR_NONE do return err
    defer os.close(dir_handle)

    // Read all files and folders inside this directory
    file_infos, read_err := os.read_dir(dir_handle, -1, context.allocator)
    if read_err != os.ERROR_NONE do return read_err
    defer delete(file_infos) // Clean up the slice allocated by read_dir

    for info in file_infos {
        // Use filepath.join to correctly stitch the parent path and the file name
        full_path, join_err := filepath.join({abs_path, info.name})
        
        // Append the current path to your dynamic array buffer
        append(path_buffer, full_path)

        // If it's a directory, recursively walk into it
        if info.type == .Directory {
            rec_err := walk_tree(full_path, path_buffer)
            if rec_err != os.ERROR_NONE {
                // Optional: Handle or return the error if a subdirectory fails to open
                return rec_err
            }
        }
    }

    return os.ERROR_NONE
}

get_absolute_path :: proc(segments: ..string) -> (value: string, ok: bool) {
    joined, join_err := os.join_path(segments[:], context.allocator)
    if join_err != nil {
        l.warning(.CONFIG, fmt.tprintf("Failed to join path for %v. Abort.", segments[:]))
        return "", false
    }

    absolute, abs_err := os.get_absolute_path(joined, context.allocator)
    if abs_err != nil {
        l.error(.CONFIG, fmt.tprintf("Failed to get absolute path for %v. err: %v", segments[:], abs_err))
        return "", false
    }

    return absolute, true
}

get_bool :: proc(L: ^lua.State, arg_pos: int) -> (value: bool, ok: bool) {
    arg_count := lua.gettop(L)
    if arg_count == 0 {
        return false, false
    }
    lua_bool_val := lua.toboolean(L, i32(arg_pos)) 
    return bool(lua_bool_val), true
}

get_string :: proc(L: ^lua.State, arg_pos: int) -> (value: string, ok: bool) {
    arg_count := lua.gettop(L)
    if arg_count == 0 {
        return "", false
    }
    c_str := lua.tostring(L, i32(arg_pos))
    if c_str == nil {
        return "", false
    }
    return string(c_str), true
}

to_string_arr :: proc(L: ^lua.State, arg: i32) -> ^[]string {
    return (^[]string)(lua.touserdata(L, arg))
}

get_int :: proc(L: ^lua.State, arg_pos: int) -> (value: int, ok: bool) {
    arg_count := lua.gettop(L)
    if arg_count == 0 {
        return -1, false
    }
    val := lua.L_checkinteger(L, i32(arg_pos))
    return int(val), true
}

get_float :: proc(L: ^lua.State, arg_pos: int) -> (value: f64, ok: bool) {
    arg_count := lua.gettop(L)
    if arg_count == 0 {
        return -1.0, false
    }
    val := lua.tonumber(L, i32(arg_pos))
    return f64(val), true
}

lua_require_function :: proc(L: ^lua.State, function_name: cstring) -> bool {
    lua.getglobal(L, function_name)
    if !lua.isfunction(L, -1) {
        lua.pop(L, 1)
        lua.close(L)
        return false
    }
    return true
}

lua_pass_args :: proc(L: ^lua.State, args: ^m.Args) {
    lua.newtable(L)

    push_string(L, "script_path", args.script_path)

    lua.pushboolean(L, b32(args.live))
    lua.setfield(L, -2, "live")

    push_string(L, "version", args.version)

    lua.pushboolean(L, b32(args.verbose))
    lua.setfield(L, -2, "verbose")
}

lua_pass_config :: proc(L: ^lua.State, cfg: ^m.Config) {
    lua.newtable(L)

    push_string(L, "version_repo", cfg.version_repo)
    push_string(L, "folder_project", cfg.folder_project)
    push_string(L, "folder_project_abs", cfg.folder_project_abs)
    push_string(L, "godot_version", cfg.godot_version)
    push_string(L, "repo_url", cfg.repo_url)
    push_string(L, "repo_branch", cfg.repo_branch)
    push_string(L, "repo_commit", cfg.repo_commit)
    push_string(L, "godot_preprocessor", cfg.godot_preprocessor)
}

lua_pass_version :: proc(L: ^lua.State, v: ^m.Version) {
    lua.newtable(L)

    push_int(L, "major", v.major)
    push_int(L, "minor", v.minor)
    push_int(L, "build_num", v.build_num)
    push_string(L, "build_type", v.build_type)
    push_string(L, "build_mode", v.build_mode)
}

@(private = "file")
push_string :: proc(L: ^lua.State, field_name: cstring, field_value: string) {
    lua.pushstring(L, strings.clone_to_cstring(field_value))
    lua.setfield(L, -2, field_name)
}

@(private = "file")
push_int :: proc(L: ^lua.State, field_name: cstring, field_value: int) {
    lua.pushinteger(L, lua.Integer(field_value))
    lua.setfield(L, -2, field_name)
}
