package export_preset

import "core:fmt"
import "core:os"
import "core:strings"
import "core:slice"
import "core:path/filepath"
import "base:runtime"
import lua "vendor:lua/5.4"

import m "../models"
import l "../logger"
import u "../utils"

FILTER_EXCLUDE :: "exclude" // all files are valid
FILTER_ALL_RESOURCES :: "all_resources" // no need to fiddle with files
FILTER_SCENES :: "scenes" // only tscn files are valid
FILTER_RESOURCES :: "resources" // anything but tscn files
FILTER_CUSTOMIZED :: "customized" // dedicated server

files_set_default :: proc(preset: ^m.ExportPreset) {
    preset.export_filter = FILTER_ALL_RESOURCES
    preset.export_files = [dynamic]string{}
    preset.include_filter = ""
    preset.exclude_filter = ""
}

files_api :: proc(L: ^lua.State) {
    lua.register(L, "export_all", lua_export_all) // no args
    lua.register(L, "exclude_dirs", lua_exclude_dirs) // table
    lua.register(L, "exclude_files", lua_exclude_files) // table
    lua.register(L, "export_scenes", lua_export_scenes) // table of scenes
    lua.register(L, "export_resources", lua_export_resources) // table of resources

    // lua.register(L, "include_dirs", lua_include_dirs)
    // lua.register(L, "include_files", lua_include_files)
    // lua.register(L, "exclude_dirs", lua_exclude_dirs)
    // lua.register(L, "exclude_files", lua_exclude_files)
    
    // old:
    // lua.register(L, "export_filter", lua_set_export_filter)
    // lua.register(L, "export_file", lua_export_file)
    // lua.register(L, "export_dir", lua_export_dir)
    
    // wildcards for file types to either include or exclude
    lua.register(L, "include_filter", lua_set_include_filter)
    lua.register(L, "exclude_filter", lua_set_exclude_filter)
}

// lua_set_export_files :: proc "c" (L: ^lua.State) -> i32 {
//     context = runtime.default_context()
//     ep := (^m.ExportPreset)(lua.touserdata(L, 1))
//     new_value := (^[]string)(lua.touserdata(L, 2))
//     if ep != nil && new_value != nil {
//         ep.export_files = new_value^
//     }
//     return 0
// }

// A C-compatible function exposed to Lua
// my_lua_function :: proc "c" (L: ^lua.lua_State) -> i32 {
//     // Ensure the first argument is a table
//     if !lua.lua_istable(L, 1) {
//         lua.luaL_error(L, "Expected a table/array as argument 1")
//         return 0
//     }

//     // Get the length of the array part of the table
//     length := lua.lua_rawlen(L, 1)
    
//     // Allocate an Odin slice or dynamic array to hold the data
//     arr := make([]f64, length)
//     defer delete(arr)

//     for i in 0 ..< length {
//         // Lua is 1-indexed, so we use i + 1
//         lua.lua_rawgeti(L, 1, i_to_lua := auto_cast (i + 1))
        
//         // Assuming an array of numbers
//         val := lua.lua_tonumber(L, -1)
//         arr[i] = auto_cast val
        
//         // Pop the element pushed by lua_rawgeti
//         lua.lua_pop(L, 1)
//     }

//     fmt.println("Received array from Lua:", arr)
//     return 0
// }

lua_export_all :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()

    can_set := ep.export_filter == ""
    if !can_set {
        l.warning(.EXPORT_PRESET, fmt.tprintf("Cannot set 'export_filter' to '%s'. It is currently '%s'.", FILTER_ALL_RESOURCES, ep.export_filter))
        return 1
    }

    ep.export_filter = FILTER_ALL_RESOURCES
    clear(&ep.export_files)

    return 0
}


lua_exclude_dirs :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()

    // This will allow the function to only run once
    can_set := ep.export_filter == "" || len(ep.export_files) == 0
    if !can_set {
        l.warning(.EXPORT_PRESET, fmt.tprintf("Cannot set 'export_filter' to '%s'. It is currently '%s'.", FILTER_EXCLUDE, ep.export_filter))
        return 1
    }

    // expect a list of directories passed as arg
    // go through list and get all files and folders

    // 1. Check if the first argument on the stack is a table
    if !lua.istable(L, 1) {
        lua.pushstring(L, "Expected a table (array) as argument")
        lua.error(L)
        return 0
    }

    // 2. Get the length of the array part of the table
    length := int(lua.rawlen(L, 1))
    
    // 3. Allocate an Odin slice or dynamic array to hold the values
    // Using a temporary allocator or standard allocation
    // resize(&ep.export_files, length)
    dirs := make([]string, length)
    defer {
        for s in dirs {
            delete(s)
        }
        delete(dirs)
    }

    // 4. Iterate 1-based (Lua convention) and pull items from the table
    for i in 1..=length {
        lua.rawgeti(L, 1, lua.Integer(i)) // Pushes t[i] onto stack

        // Verify the element is actually a string (or convertible to one)
        if !lua.isstring(L, -1) {
            lua.pop(L, 1)
            lua.pushstring(L, "All elements in the array must be strings")
            lua.error(L)
            return 0
        }

        c_str := lua.tostring(L, -1)
        // Clone the cstring into an Odin-managed string before popping
        dirs[i - 1] = strings.clone_from_cstring(c_str)
        lua.pop(L, 1) // Pop t[i] from the stack
    }

    fmt.printfln("Received array in Odin: %v", dirs)

    // for each string in dirs
    // walk the tree, collect files and folders in export_files

    ep.export_filter = FILTER_EXCLUDE

    return 0
}

lua_exclude_files :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()

    // This will allow the function to be called multiple
    // times as long as the filter doesn't change
    can_set := ep.export_filter == "" || ep.export_filter == FILTER_EXCLUDE
    if !can_set {
        l.warning(.EXPORT_PRESET, fmt.tprintf("Cannot set 'export_filter' to '%s'. It is currently '%s'.", FILTER_EXCLUDE, ep.export_filter))
        return 1
    }

    // get files from args
    // append to ep.export_files

    return 0
}

lua_export_scenes :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()

    valid_filter := 
        ep.export_filter == "" || 
        ep.export_filter == ""

    return 0
}

lua_export_resources :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    return 0
}



// old?
lua_set_export_filter :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    
    filter, ok_filter := u.get_string(L, 1)
    if !ok_filter {
        l.warning(.EXPORT_PRESET, "Cannot get export_filter from lua")
        return 1
    }

    valid_filters := [5]string{
        "exclude",
        "all_resources",
        "scenes",
        "resources",
        "customized",
    }

    if !slice.contains(valid_filters[:], filter) {
        l.error(.EXPORT_PRESET, fmt.tprintf("Invalid filter: %s", filter))
        return 1
    }

    // when filter is server thing, change the backing field files to that other thing.
    ep.export_filter = filter
    return 0
}

lua_export_file :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    file_path_rel, ok_lua := u.get_string(L, 1)
    if !ok_lua {
        return 1
    }
    res_path := fmt.tprintf("res://%s", file_path_rel)
    append(&ep.export_files, res_path)
    return 0
}

lua_export_dir :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    
    dir, dir_ok := u.get_string(L, 1)
    if !dir_ok {
        return 1
    }
    
    walk_path, walk_ok := u.get_absolute_path(cfg.folder_project_abs, dir)
    defer delete(walk_path)
    if !walk_ok {
        return 1
    }

    // collect all files and sub directories. Should be an ok
    // default behaviour. Doesn't make sense to add only a folder
    // without the contents(?)
    paths := make([dynamic]string)
    if u.walk_tree(walk_path, &paths) != nil {
        l.warning(.EXPORT_PRESET, "Could not traverse tree")
    }
    
    for file_path in paths {
        if os.is_directory(file_path) {
            continue
        }
        res_path, ok := create_res_path(cfg.folder_project_abs, file_path)
        if !ok {
            continue
        }
        append(&ep.export_files, res_path)
    }
    
    return 0
}
