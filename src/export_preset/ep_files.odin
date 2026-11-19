package export_preset

import "core:fmt"
import "core:os"
import "core:strings"
import "base:runtime"
import lua "vendor:lua/5.4"

import m "../models"
import l "../logger"
import u "../utils"

FILTER_EXCLUDE          :: "exclude"        // all files are valid
FILTER_ALL_RESOURCES    :: "all_resources"  // no need to fiddle with files
FILTER_SCENES           :: "scenes"         // only tscn files are valid
FILTER_RESOURCES        :: "resources"      // anything but tscn files
FILTER_CUSTOMIZED       :: "customized"     // dedicated server

files_api :: proc(L: ^lua.State) {
    lua.register(L, "export_all", lua_export_all) // no args
    lua.register(L, "exclude", lua_exclude_files_and_dirs) // table
    lua.register(L, "export_scenes", lua_export_scenes) // table of scenes
    lua.register(L, "export_resources", lua_export_resources) // table of resources

    // wildcards for file types to either include or exclude
    lua.register(L, "include_filter", lua_set_include_filter)
    lua.register(L, "exclude_filter", lua_set_exclude_filter)

    lua.register(L, "dedicated_server", lua_set_dedicated_server)

    // dedicated_server(bool)
    // - sets export_filter to CUSTOMIZED
    // - sets dedicated_server to true
    // - clear export_files
    // - or replace with customized_files. Which is a dictionary of
    // resource path : value (strip, keep, remove) // what's the difference between strip and remove?
}

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

lua_exclude_files_and_dirs :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()

    // This will allow the function to run when no filter is set,
    // and to call the function multiple times as long as the
    // correct filter is set.
    can_set := ep.export_filter == "" || ep.export_filter == FILTER_EXCLUDE
    if !can_set {
        l.warning(.EXPORT_PRESET, fmt.tprintf("Cannot set 'export_filter' to '%s'. It is currently '%s'.", FILTER_EXCLUDE, ep.export_filter))
        return 1
    }

    dirs := make([dynamic]string)
    did_get_arr := get_array_from_args(L, &dirs)
    if !did_get_arr {
        return 1
    }

    for dir in dirs {
        dir_abs, abs_ok := u.get_absolute_path(cfg.folder_project_abs, dir)
        defer delete(dir_abs)
        
        if !abs_ok {
            continue
        }

        // if dir is in fact a file, append it
        if os.is_file(dir_abs) {
            res_path, ok := create_res_path(cfg.folder_project_abs, dir_abs)
            if ok {
                append(&ep.export_files, res_path)
            }

            continue
        }

        // if dir is a dir, walk the tree
        result := walk_tree(dir_abs, &ep.export_files)
        if result != 0 {
            l.warning(.EXPORT_PRESET, fmt.tprintf("Could not get all files and folders from '%s'", dir))
        }

        // Append the directory itself
        res_path, ok := create_res_path("", dir)
        if ok {
            append(&ep.export_files, res_path)
        }
    }

    ep.export_filter = FILTER_EXCLUDE

    return 0
}

lua_export_scenes :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()

    extensions := [3]string{ ".tscn", ".scn", ".escn" }

    // This will allow the function to run when no filter is set,
    // and to call the function multiple times as long as the
    // correct filter is set.
    can_set := ep.export_filter == "" || ep.export_filter == FILTER_SCENES
    if !can_set {
        // TODO: Provide a more helpful warning. This happens because one of the
        // other exclude/include functions have already been run
        l.warning(.EXPORT_PRESET, fmt.tprintf("Cannot set 'export_filter' to '%s'. It is currently '%s'.", FILTER_SCENES, ep.export_filter))
        return 1
    }

    scenes := make([dynamic]string)
    defer {
        for s in scenes {
            delete(s)
        }
        delete(scenes)
    }

    did_get_arr := get_array_from_args(L, &scenes)
    if !did_get_arr {
        return 1
    }

    for scene in scenes {
        valid_file := false
        for ext in extensions {
            if strings.ends_with(scene, ext) {
                valid_file = true
            }
        }

        if !valid_file {
            l.warning(.EXPORT_PRESET, fmt.tprintf("Did not recognize '%s' as a valid file", scene))
            continue
        }

        scene_abs, abs_ok := u.get_absolute_path(cfg.folder_project_abs, scene)
        defer delete(scene_abs)
        
        if !abs_ok {
            continue
        }

        res_path, ok := create_res_path(cfg.folder_project_abs, scene_abs)
        if ok {
            append(&ep.export_files, res_path)
        }
    }

    ep.export_filter = FILTER_SCENES

    return 0
}

lua_export_resources :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()

    // Almost anything can be a resource. Custom resources can be added.
    // There is no way of know exactly all possible resource file extensions.

    // This will allow the function to run when no filter is set,
    // and to call the function multiple times as long as the
    // correct filter is set.
    can_set := ep.export_filter == "" || ep.export_filter == FILTER_RESOURCES
    if !can_set {
        // TODO: Provide a more helpful warning. This happens because one of the
        // other exclude/include functions have already been run
        l.warning(.EXPORT_PRESET, fmt.tprintf("Cannot set 'export_filter' to '%s'. It is currently '%s'.", FILTER_RESOURCES, ep.export_filter))
        return 1
    }

    paths := make([dynamic]string)
    defer {
        for s in paths {
            delete(s)
        }
        delete(paths)
    }

    did_get_arr := get_array_from_args(L, &paths)
    if !did_get_arr {
        return 1
    }

    for file_path in paths {
        file_path_abs, abs_ok := u.get_absolute_path(cfg.folder_project_abs, file_path)
        defer delete(file_path_abs)
        
        if !abs_ok {
            continue
        }

        res_path, ok := create_res_path(cfg.folder_project_abs, file_path_abs)
        if ok {
            append(&ep.export_files, res_path)
        }
    }

    ep.export_filter = FILTER_RESOURCES

    return 0
}

lua_set_include_filter :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    
    // Note: same as in exclude_filter. If this gets used elsewhere, make it a util function
    filters := make([dynamic]string)
    defer {
        for s in filters {
            delete(s)
        }
        delete(filters)
    }

    did_get_arr := get_array_from_args(L, &filters)
    if !did_get_arr {
        return 1
    }

    filter_str, join_err := strings.join(filters[:], ",")
    if join_err != nil {
        l.warning(.EXPORT_PRESET, fmt.tprint("Could not join filters into a string"))
        return 1
    }

    ep.include_filter = filter_str
    
    return 0
}

lua_set_exclude_filter :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()

    filters := make([dynamic]string)
    defer {
        for s in filters {
            delete(s)
        }
        delete(filters)
    }

    did_get_arr := get_array_from_args(L, &filters)
    if !did_get_arr {
        return 1
    }

    filter_str, join_err := strings.join(filters[:], ",")
    if join_err != nil {
        l.warning(.EXPORT_PRESET, fmt.tprint("Could not join filters into a string"))
        return 1
    }

    ep.exclude_filter = filter_str
    
    return 0
}


lua_set_dedicated_server :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    if b, ok := u.get_bool(L, 1); ok {
        ep.dedicated_server = b
    }
    return 0
}
