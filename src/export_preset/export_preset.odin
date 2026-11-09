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

ep: ^m.ExportPreset
cfg: ^m.Config

// for lua to add custom settings for addons, a more generic function for setting key value pairs
// should be accessible. set_bool("imgui/debug", false), set_string, set_int, set_array ..

hook :: proc(preset: ^m.ExportPreset, args: ^m.Args, config: ^m.Config, version: ^m.Version) {
    L: ^lua.State
    L = lua.L_newstate()
    lua.L_openlibs(L) // add standard libs to lua script

    ep = preset
    cfg = config

    set_defaults(preset)
    register_api(L)

    lua.L_dofile(L, strings.clone_to_cstring(args.script_path))

    if !u.lua_require_function(L, "create_export_preset") {
        l.fatal(.EXPORT_PRESET, fmt.tprintf("No 'create_export_preset' function found in %s. Cannot export Godot project", args.script_path))
        os.exit(1)
    }

    u.lua_pass_args(L, args)
    u.lua_pass_config(L, config)
    u.lua_pass_version(L, version)

    // Call the function
    if lua.pcall(L, 3, 0, 0) != 0 {
        err_msg := lua.tostring(L, -1)
        l.error(.EXPORT_PRESET, strings.clone_from_cstring(err_msg))
        fmt.println("Lua err: ", err_msg)
    }

    // Default to writing to project folder
    preset_path, join_err := filepath.join({".", "export_presets.cfg"})
    if join_err != nil {
        l.error(.CONFIG, fmt.tprintf("Cannot create file path for ./export_presets.cfg. Export presets will not be updated."))
        return
    }

    write_file(ep, preset_path)
}

@(private = "file")
set_defaults :: proc(preset: ^m.ExportPreset) {
    preset.name = ""
    preset.platform = ""
    preset.runnable = true
    preset.dedicated_server = false
    preset.custom_features = ""

    files_set_default(preset)

    // preset.export_path = ""
    preset.patches = [dynamic]string{}
    preset.patch_delta_encoding = false
    preset.patch_delta_compression_level_zstd = 19
    preset.patch_delta_min_reduction = 0.1
    preset.patch_delta_include_filters = "*"
    preset.patch_delta_exclude_filters = ""
    preset.encryption_include_filters = ""
    preset.encryption_exclude_filters = ""
    preset.seed = 0
    preset.encrypt_pck = false
    preset.encrypt_directory = false
    preset.script_export_mode = 2

    preset.options.custom_template_debug = ""
    preset.options.custom_template_release = ""
    preset.options.debug_export_console_wrapper = 0
    preset.options.binary_format_embed_pck = false
    preset.options.texture_format_s3tc_bptc = true
    preset.options.texture_format_etc2_astc = false
    preset.options.shader_baker_enabled = true
    preset.options.binary_format_architecture = "x86_64"
    preset.options.codesign_enable = false
    preset.options.codesign_timestamp = true
    preset.options.codesign_timestamp_server_url = ""
    preset.options.codesign_digest_algorithm = 1
    preset.options.codesign_description = ""
    preset.options.codesign_custom_options = [dynamic]string{}
    preset.options.application_modify_resources = true
    preset.options.application_icon = ""
    preset.options.application_console_wrapper_icon = ""
    preset.options.application_icon_interpolation = 4
    preset.options.application_file_version = ""
    preset.options.application_product_version = ""
    preset.options.application_company_name = ""
    preset.options.application_product_name = ""
    preset.options.application_file_description = ""
    preset.options.application_copyright = ""
    preset.options.application_trademarks = ""
    preset.options.application_export_angle = 0
    preset.options.application_export_d3d12 = 0
    preset.options.application_d3d12_agility_sdk_multiarch = true
    preset.options.ssh_remote_deploy_enabled = false
    preset.options.ssh_remote_deploy_host = "user@host_ip"
    preset.options.ssh_remote_deploy_port = "22"
    preset.options.ssh_remote_deploy_extra_args_ssh = ""
    preset.options.ssh_remote_deploy_extra_args_scp = ""
    preset.options.ssh_remote_deploy_run_script = "Expand-Archive -LiteralPath '{temp_dir}\\{archive_name}' -DestinationPath '{temp_dir}'\n$action = New-ScheduledTaskAction -Execute '{temp_dir}\\{exe_name}' -Argument '{cmd_args}'\n$trigger = New-ScheduledTaskTrigger -Once -At 00:00\n$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries\n$task = New-ScheduledTask -Action $action -Trigger $trigger -Settings $settings\nRegister-ScheduledTask godot_remote_debug -InputObject $task -Force:$true\nStart-ScheduledTask -TaskName godot_remote_debug\nwhile (Get-ScheduledTask -TaskName godot_remote_debug | ? State -eq running) { Start-Sleep -Milliseconds 100 }"
    preset.options.ssh_remote_deploy_cleanup_script = "Stop-ScheduledTask -TaskName godot_remote_debug -ErrorAction:SilentlyContinue\nUnregister-ScheduledTask -TaskName godot_remote_debug -Confirm:$false -ErrorAction:SilentlyContinue\nRemove-Item -Recurse -Force '{temp_dir}'"
}

@(private = "file")
register_api :: proc(L: ^lua.State) {
    lua.register(L, "name", lua_set_name)
    lua.register(L, "platform", lua_set_platform)
    lua.register(L, "runnable", lua_set_runnable)
    lua.register(L, "dedicated_server", lua_set_dedicated_server)
    lua.register(L, "custom_features", lua_set_custom_features)

    files_api(L)

    // lua.register(L, "export_path", lua_set_export_path)
    // lua.register(L, "patches", lua_set_patches)
    lua.register(L, "patch_delta_encoding", lua_set_patch_delta_encoding)
    lua.register(L, "patch_delta_compression_level_zstd", lua_set_patch_delta_compression_level_zstd)
    lua.register(L, "patch_delta_min_reduction", lua_set_patch_delta_min_reduction)
    lua.register(L, "patch_delta_include_filters", lua_set_patch_delta_include_filters)
    lua.register(L, "patch_delta_exclude_filters", lua_set_patch_delta_exclude_filters)
    lua.register(L, "encryption_include_filters", lua_set_encryption_include_filters)
    lua.register(L, "encryption_exclude_filters", lua_set_encryption_exclude_filters)
    lua.register(L, "seed", lua_set_seed)
    lua.register(L, "encrypt_pck", lua_set_encrypt_pck)
    lua.register(L, "encrypt_directory", lua_set_encrypt_directory)
    lua.register(L, "script_export_mode", lua_set_script_export_mode)
    lua.register(L, "custom_template_debug", lua_set_custom_template_debug)
    lua.register(L, "custom_template_release", lua_set_custom_template_release)
    lua.register(L, "debug_export_console_wrapper", lua_set_debug_export_console_wrapper)
    lua.register(L, "binary_format_embed_pck", lua_set_binary_format_embed_pck)
    lua.register(L, "texture_format_s3tc_bptc", lua_set_texture_format_s3tc_bptc)
    lua.register(L, "texture_format_etc2_astc", lua_set_texture_format_etc2_astc)
    lua.register(L, "shader_baker_enabled", lua_set_shader_baker_enabled)
    lua.register(L, "binary_format_architecture", lua_set_binary_format_architecture)
    // lua.register(L, "codesign_enable", lua_set_codesign_enable)
    // lua.register(L, "codesign_timestamp", lua_set_codesign_timestamp)
    // lua.register(L, "codesign_timestamp_server_url", lua_set_codesign_timestamp_server_url)
    // lua.register(L, "codesign_digest_algorithm", lua_set_codesign_digest_algorithm)
    // lua.register(L, "codesign_description", lua_set_codesign_description)
    // lua.register(L, "codesign_custom_options", lua_set_codesign_custom_options)
    lua.register(L, "application_modify_resources", lua_set_application_modify_resources)
    lua.register(L, "application_icon", lua_set_application_icon)
    lua.register(L, "application_console_wrapper_icon", lua_set_application_console_wrapper_icon)
    lua.register(L, "application_icon_interpolation", lua_set_application_icon_interpolation)
    lua.register(L, "application_file_version", lua_set_application_file_version)
    lua.register(L, "application_product_version", lua_set_application_product_version)
    lua.register(L, "application_company_name", lua_set_application_company_name)
    lua.register(L, "application_product_name", lua_set_application_product_name)
    lua.register(L, "application_file_description", lua_set_application_file_description)
    lua.register(L, "application_copyright", lua_set_application_copyright)
    lua.register(L, "application_trademarks", lua_set_application_trademarks)
    lua.register(L, "application_export_angle", lua_set_application_export_angle)
    lua.register(L, "application_export_d3d12", lua_set_application_export_d3d12)
    lua.register(L, "application_d3d12_agility_sdk_multiarch", lua_set_application_d3d12_agility_sdk_multiarch)
    lua.register(L, "ssh_remote_deploy_enabled", lua_set_ssh_remote_deploy_enabled)
    lua.register(L, "ssh_remote_deploy_host", lua_set_ssh_remote_deploy_host)
    lua.register(L, "ssh_remote_deploy_port", lua_set_ssh_remote_deploy_port)
    lua.register(L, "ssh_remote_deploy_extra_args_ssh", lua_set_ssh_remote_deploy_extra_args_ssh)
    lua.register(L, "ssh_remote_deploy_extra_args_scp", lua_set_ssh_remote_deploy_extra_args_scp)
    lua.register(L, "ssh_remote_deploy_run_script", lua_set_ssh_remote_deploy_run_script)
    lua.register(L, "ssh_remote_deploy_cleanup_script", lua_set_ssh_remote_deploy_cleanup_script)
}


// Implement later, when needed
// lua_set_codesign_custom_options :: proc "c" (L: ^lua.State) -> i32 {
//     context = runtime.default_context()
//     ep := (^ExportPreset)(lua.touserdata(L, 1))
//     new_value := (^[]string)(lua.touserdata(L, 2))
//     if ep != nil && ep.options != nil && new_value != nil {
//         ep.options.codesign_custom_options = new_value^
//     }
//     return 0
// }

create_res_path :: proc(base_path: string, target_path: string) -> (res_path: string, ok: bool) {
    rel_path, err := filepath.rel(base_path, target_path)
    if err != .None {
        l.warning(.EXPORT_PRESET, fmt.tprintf("Could not get relative path for %s > %s", base_path, target_path))
        return "", false
    }
    return fmt.tprintf("res://%s", rel_path), true
}

// lua_set_patches :: proc "c" (L: ^lua.State) -> i32 {
//     context = runtime.default_context()
//     ep := (^m.ExportPreset)(lua.touserdata(L, 1))
//     new_value := (^[]string)(lua.touserdata(L, 2))
//     if ep != nil && new_value != nil {
//         ep.patches = new_value^
//     }
//     return 0
// }

lua_set_name :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    if s, ok := u.get_string(L, 1); ok {
        ep.name = s
    }
    return 0
}

lua_set_platform :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    if s, ok := u.get_string(L, 1); ok {
        ep.platform = s
    }
    return 0
}

lua_set_runnable :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    if b, ok := u.get_bool(L, 1); ok {
        ep.runnable = b
    }
    return 0
}

lua_set_dedicated_server :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    if b, ok := u.get_bool(L, 1); ok {
        ep.dedicated_server = b
    }
    return 0
}

lua_set_custom_features :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    if s, ok := u.get_string(L, 1); ok {
        ep.custom_features = s
    }
    return 0
}



lua_set_include_filter :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    if s, ok := u.get_string(L, 1); ok {
        ep.include_filter = s
    }
    return 0
}

lua_set_exclude_filter :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    if s, ok := u.get_string(L, 1); ok {
        ep.exclude_filter = s
    }
    return 0
}

// lua_set_export_path :: proc "c" (L: ^lua.State) -> i32 {
//     context = runtime.default_context()
//     if s, ok := u.get_string(L, 1); ok {
//         ep.export_path = s
//     }
//     return 0
// }

lua_set_patch_delta_encoding :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    if b, ok := u.get_bool(L, 1); ok {
        ep.patch_delta_encoding = b
    }
    return 0
}

lua_set_patch_delta_compression_level_zstd :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    if i, ok := u.get_int(L, 1); ok {
        ep.patch_delta_compression_level_zstd = i
    }
    return 0
}

lua_set_patch_delta_min_reduction :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    if f, ok := u.get_float(L, 1); ok {
        ep.patch_delta_min_reduction = f
    }
    return 0
}

lua_set_patch_delta_include_filters :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    if s, ok := u.get_string(L, 1); ok {
        ep.patch_delta_include_filters = s
    }
    return 0
}

lua_set_patch_delta_exclude_filters :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    if s, ok := u.get_string(L, 1); ok {
        ep.patch_delta_exclude_filters = s
    }
    return 0
}

lua_set_encryption_include_filters :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    if s, ok := u.get_string(L, 1); ok {
        ep.encryption_include_filters = s
    }
    return 0
}

lua_set_encryption_exclude_filters :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    if s, ok := u.get_string(L, 1); ok {
        ep.encryption_exclude_filters = s
    }
    return 0
}

lua_set_seed :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    if i, ok := u.get_int(L, 1); ok {
        ep.seed = i
    }
    return 0
}

lua_set_encrypt_pck :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    if b, ok := u.get_bool(L, 1); ok {
        ep.encrypt_pck = b
    }
    return 0
}

lua_set_encrypt_directory :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    if b, ok := u.get_bool(L, 1); ok {
        ep.encrypt_directory = b
    }
    return 0
}

lua_set_script_export_mode :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()

    mode, ok_mode := u.get_string(L, 1)
    if !ok_mode {
        l.warning(.EXPORT_PRESET, "Cannot get script_export_mode from lua")
        return 1
    }

    ExportMode :: enum {
        Text = 0,
        BinaryToken = 1,
        CompressedBinaryToken = 2,
    }

    export_mode: ExportMode

    switch mode {
        case "text":
            export_mode = .Text
        case "binary_token":
            export_mode = .BinaryToken
        case "compressed_binary_token":
            export_mode = .CompressedBinaryToken
        case:
            l.error(.EXPORT_PRESET, fmt.tprintf("Invalid script export mode: %s", export_mode))
            return 1
    }

    ep.script_export_mode = int(export_mode)
    return 0
}

lua_set_custom_template_debug :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    if s, ok := u.get_string(L, 1); ok {
        ep.options.custom_template_debug = s
    }
    return 0
}

lua_set_custom_template_release :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    if s, ok := u.get_string(L, 1); ok {
        ep.options.custom_template_release = s
    }
    return 0
}

lua_set_debug_export_console_wrapper :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    if i, ok := u.get_int(L, 1); ok {
        ep.options.debug_export_console_wrapper = i
    }
    return 0
}

lua_set_binary_format_embed_pck :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    if b, ok := u.get_bool(L, 1); ok {
        ep.options.binary_format_embed_pck = b
    }
    return 0
}

lua_set_texture_format_s3tc_bptc :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    if b, ok := u.get_bool(L, 1); ok {
        ep.options.texture_format_s3tc_bptc = b
    }
    return 0
}

lua_set_texture_format_etc2_astc :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    if b, ok := u.get_bool(L, 1); ok {
        ep.options.texture_format_etc2_astc = b
    }
    return 0
}

lua_set_shader_baker_enabled :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    if b, ok := u.get_bool(L, 1); ok {
        ep.options.shader_baker_enabled = b
    }
    return 0
}

lua_set_binary_format_architecture :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    if s, ok := u.get_string(L, 1); ok {
        ep.options.binary_format_architecture = s
    }
    return 0
}

lua_set_codesign_enable :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    if b, ok := u.get_bool(L, 1); ok {
        ep.options.codesign_enable = b
    }
    return 0
}

lua_set_codesign_timestamp :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    if b, ok := u.get_bool(L, 1); ok {
        ep.options.codesign_timestamp = b
    }
    return 0
}

lua_set_codesign_timestamp_server_url :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    if s, ok := u.get_string(L, 1); ok {
        ep.options.codesign_timestamp_server_url = s
    }
    return 0
}

lua_set_codesign_digest_algorithm :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    if i, ok := u.get_int(L, 1); ok {
        ep.options.codesign_digest_algorithm = i
    }
    return 0
}

lua_set_codesign_description :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    if s, ok := u.get_string(L, 1); ok {
        ep.options.codesign_description = s
    }
    return 0
}

lua_set_application_modify_resources :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    if b, ok := u.get_bool(L, 1); ok {
        ep.options.application_modify_resources = b
    }
    return 0
}

lua_set_application_icon :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    if s, ok := u.get_string(L, 1); ok {
        ep.options.application_icon = s
    }
    return 0
}

lua_set_application_console_wrapper_icon :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    if s, ok := u.get_string(L, 1); ok {
        ep.options.application_console_wrapper_icon = s
    }
    return 0
}

lua_set_application_icon_interpolation :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    if i, ok := u.get_int(L, 1); ok {
        ep.options.application_icon_interpolation = i
    }
    return 0
}

lua_set_application_file_version :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    if s, ok := u.get_string(L, 1); ok {
        ep.options.application_file_version = s
    }
    return 0
}

lua_set_application_product_version :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    if s, ok := u.get_string(L, 1); ok {
        ep.options.application_product_version = s
    }
    return 0
}

lua_set_application_company_name :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    if s, ok := u.get_string(L, 1); ok {
        ep.options.application_company_name = s
    }
    return 0
}

lua_set_application_product_name :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    if s, ok := u.get_string(L, 1); ok {
        ep.options.application_product_name = s
    }
    return 0
}

lua_set_application_file_description :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    if s, ok := u.get_string(L, 1); ok {
        ep.options.application_file_description = s
    }
    return 0
}

lua_set_application_copyright :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    if s, ok := u.get_string(L, 1); ok {
        ep.options.application_copyright = s
    }
    return 0
}

lua_set_application_trademarks :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    if s, ok := u.get_string(L, 1); ok {
        ep.options.application_trademarks = s
    }
    return 0
}

lua_set_application_export_angle :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    if i, ok := u.get_int(L, 1); ok {
        ep.options.application_export_angle = i
    }
    return 0
}
lua_set_application_export_d3d12 :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    if i, ok := u.get_int(L, 1); ok {
        ep.options.application_export_d3d12 = i
    }
    return 0
}

lua_set_application_d3d12_agility_sdk_multiarch :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    if b, ok := u.get_bool(L, 1); ok {
        ep.options.application_d3d12_agility_sdk_multiarch = b
    }
    return 0
}

lua_set_ssh_remote_deploy_enabled :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    if b, ok := u.get_bool(L, 1); ok {
        ep.options.ssh_remote_deploy_enabled = b
    }
    return 0
}

lua_set_ssh_remote_deploy_host :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    if s, ok := u.get_string(L, 1); ok {
        ep.options.ssh_remote_deploy_host = s
    }
    return 0
}

lua_set_ssh_remote_deploy_port :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    if s, ok := u.get_string(L, 1); ok {
        ep.options.ssh_remote_deploy_port = s
    }
    return 0
}

lua_set_ssh_remote_deploy_extra_args_ssh :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    if s, ok := u.get_string(L, 1); ok {
        ep.options.ssh_remote_deploy_extra_args_ssh = s
    }
    return 0
}

lua_set_ssh_remote_deploy_extra_args_scp :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    if s, ok := u.get_string(L, 1); ok {
        ep.options.ssh_remote_deploy_extra_args_scp = s
    }
    return 0
}

lua_set_ssh_remote_deploy_run_script :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    if s, ok := u.get_string(L, 1); ok {
        ep.options.ssh_remote_deploy_run_script = s
    }
    return 0
}

lua_set_ssh_remote_deploy_cleanup_script :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    if s, ok := u.get_string(L, 1); ok {
        ep.options.ssh_remote_deploy_cleanup_script = s
    }
    return 0
}
