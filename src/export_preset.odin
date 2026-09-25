package main

import "core:fmt"
import "core:os"
import "core:strings"
import "core:path/filepath"
import "base:runtime"
import lua "vendor:lua/5.4"

import "models"
import "logger"

ExportPresetOptions :: struct {
    custom_template_debug:              string,
    custom_template_release:            string,
    debug_export_console_wrapper:       int,
    binary_format_embed_pck:             bool,
    texture_format_s3tc_bptc:            bool,
    texture_format_etc2_astc:            bool,
    shader_baker_enabled:                bool,
    binary_format_architecture:          string,
    codesign_enable:                     bool,
    codesign_timestamp:                  bool,
    codesign_timestamp_server_url:       string,
    codesign_digest_algorithm:           int,
    codesign_description:                string,
    codesign_custom_options:             []string,
    application_modify_resources:        bool,
    application_icon:                    string,
    application_console_wrapper_icon:    string,
    application_icon_interpolation:      int,
    application_file_version:            string,
    application_product_version:         string,
    application_company_name:            string,
    application_product_name:            string,
    application_file_description:        string,
    application_copyright:                string,
    application_trademarks:               string,
    application_export_angle:             int,
    application_export_d3d12:             int,
    application_d3d12_agility_sdk_multiarch: bool,
    ssh_remote_deploy_enabled:            bool,
    ssh_remote_deploy_host:               string,
    ssh_remote_deploy_port:               string,
    ssh_remote_deploy_extra_args_ssh:     string,
    ssh_remote_deploy_extra_args_scp:     string,
    ssh_remote_deploy_run_script:         string,
    ssh_remote_deploy_cleanup_script:     string,

    // some kind of dictionary for holding custom addon settings
    // sentry/asdf
    // imgui/debug=false etc
}

ExportPreset :: struct {
    name:                  string,
    platform:              string,
    runnable:              bool,
    dedicated_server:      bool,
    custom_features:       string,
    export_filter:         string,
    export_files:          []string,
    include_filter:        string,
    exclude_filter:        string,
    export_path:           string,
    patches:               []string,
    patch_delta_encoding:  bool,
    patch_delta_compression_level_zstd: int,
    patch_delta_min_reduction:          f64,
    patch_delta_include_filters:        string,
    patch_delta_exclude_filters:        string,
    encryption_include_filters:          string,
    encryption_exclude_filters:          string,
    seed:                   int,
    encrypt_pck:            bool,
    encrypt_directory:      bool,
    script_export_mode:     int,

    options: ^ExportPresetOptions,
}


@(private = "file")
set_default_preset :: proc(preset: ^ExportPreset) {
    preset.name = ""
    preset.platform = ""
    preset.runnable = false
    preset.dedicated_server = false
    preset.custom_features = ""
    preset.export_filter = ""
    preset.export_files = []string{}
    preset.include_filter = ""
    preset.exclude_filter = ""
    preset.export_path = ""
    preset.patches = []string{}
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

    preset.options = new(ExportPresetOptions)
    set_default_options(preset.options)
}

@(private = "file")
set_default_options :: proc(options: ^ExportPresetOptions) {
    options.custom_template_debug = ""
    options.custom_template_release = ""
    options.debug_export_console_wrapper = 0
    options.binary_format_embed_pck = false
    options.texture_format_s3tc_bptc = true
    options.texture_format_etc2_astc = false
    options.shader_baker_enabled = true
    options.binary_format_architecture = "x86_64"
    options.codesign_enable = false
    options.codesign_timestamp = true
    options.codesign_timestamp_server_url = ""
    options.codesign_digest_algorithm = 1
    options.codesign_description = ""
    options.codesign_custom_options = []string{}
    options.application_modify_resources = true
    options.application_icon = ""
    options.application_console_wrapper_icon = ""
    options.application_icon_interpolation = 4
    options.application_file_version = ""
    options.application_product_version = ""
    options.application_company_name = ""
    options.application_product_name = ""
    options.application_file_description = ""
    options.application_copyright = ""
    options.application_trademarks = ""
    options.application_export_angle = 0
    options.application_export_d3d12 = 0
    options.application_d3d12_agility_sdk_multiarch = true
    options.ssh_remote_deploy_enabled = false
    options.ssh_remote_deploy_host = "user@host_ip"
    options.ssh_remote_deploy_port = "22"
    options.ssh_remote_deploy_extra_args_ssh = ""
    options.ssh_remote_deploy_extra_args_scp = ""
    options.ssh_remote_deploy_run_script = "Expand-Archive -LiteralPath '{temp_dir}\\{archive_name}' -DestinationPath '{temp_dir}'\n$action = New-ScheduledTaskAction -Execute '{temp_dir}\\{exe_name}' -Argument '{cmd_args}'\n$trigger = New-ScheduledTaskTrigger -Once -At 00:00\n$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries\n$task = New-ScheduledTask -Action $action -Trigger $trigger -Settings $settings\nRegister-ScheduledTask godot_remote_debug -InputObject $task -Force:$true\nStart-ScheduledTask -TaskName godot_remote_debug\nwhile (Get-ScheduledTask -TaskName godot_remote_debug | ? State -eq running) { Start-Sleep -Milliseconds 100 }"
    options.ssh_remote_deploy_cleanup_script = "Stop-ScheduledTask -TaskName godot_remote_debug -ErrorAction:SilentlyContinue\nUnregister-ScheduledTask -TaskName godot_remote_debug -Confirm:$false -ErrorAction:SilentlyContinue\nRemove-Item -Recurse -Force '{temp_dir}'"
}

@(private = "file")
serialize :: proc(preset: ^ExportPreset) -> string {
    sb := strings.builder_make()
    defer strings.builder_destroy(&sb)

    // Shouldn't be necessary to support custom numbering, as
    // export presets will be generated for every build target
    fmt.sbprintfln(&sb, "[preset.0]")

    fmt.sbprintfln(&sb, "name=%q", preset.name)
    fmt.sbprintfln(&sb, "platform=%q", preset.platform)
    fmt.sbprintfln(&sb, "runnable=%v", preset.runnable)
    fmt.sbprintfln(&sb, "dedicated_server=%v", preset.dedicated_server)
    fmt.sbprintfln(&sb, "custom_features=%q", preset.custom_features)
    fmt.sbprintfln(&sb, "export_path=%q", preset.export_path)

    fmt.sbprintfln(&sb, "export_filter=%q", preset.export_filter)
    serialize_packed_string_array(&sb, "export_files", preset.export_files)
    fmt.sbprintfln(&sb, "include_filter=%q", preset.include_filter)
    fmt.sbprintfln(&sb, "exclude_filter=%q", preset.exclude_filter)

    serialize_packed_string_array(&sb, "patches", preset.patches)
    fmt.sbprintfln(&sb, "patch_delta_encoding=%v", preset.patch_delta_encoding)
    fmt.sbprintfln(&sb, "patch_delta_compression_level_zstd=%d", preset.patch_delta_compression_level_zstd)
    fmt.sbprintfln(&sb, "patch_delta_min_reduction=%g", preset.patch_delta_min_reduction)
    fmt.sbprintfln(&sb, "patch_delta_include_filters=%q", preset.patch_delta_include_filters)
    fmt.sbprintfln(&sb, "patch_delta_exclude_filters=%q", preset.patch_delta_exclude_filters)

    fmt.sbprintfln(&sb, "encryption_include_filters=%q", preset.encryption_include_filters)
    fmt.sbprintfln(&sb, "encryption_exclude_filters=%q", preset.encryption_exclude_filters)
    fmt.sbprintfln(&sb, "encrypt_pck=%v", preset.encrypt_pck)
    fmt.sbprintfln(&sb, "encrypt_directory=%v", preset.encrypt_directory)
    fmt.sbprintfln(&sb, "seed=%d", preset.seed)

    // Use an enum instead? How does that work with Lua?
    fmt.sbprintfln(&sb, "script_export_mode=%d", preset.script_export_mode)

    // Options

    fmt.sbprintfln(&sb, "")
    fmt.sbprintfln(&sb, "[preset.0.options]")

    fmt.sbprintfln(&sb, "custom_template/debug=%q", preset.options.custom_template_debug)
    fmt.sbprintfln(&sb, "custom_template/release=%q", preset.options.custom_template_release)

    fmt.sbprintfln(&sb, "debug/export_console_wrapper=%d", preset.options.debug_export_console_wrapper)

    fmt.sbprintfln(&sb, "binary_format/embed_pck=%v", preset.options.binary_format_embed_pck)
    fmt.sbprintfln(&sb, "binary_format/architecture=%q", preset.options.binary_format_architecture)

    fmt.sbprintfln(&sb, "texture_format/s3tc_bptc=%v", preset.options.texture_format_s3tc_bptc)
    fmt.sbprintfln(&sb, "texture_format/etc2_astc=%v", preset.options.texture_format_etc2_astc)

    fmt.sbprintfln(&sb, "shader_baker/enabled=%v", preset.options.shader_baker_enabled)

    fmt.sbprintfln(&sb, "codesign/enable=%v", preset.options.codesign_enable)
    fmt.sbprintfln(&sb, "codesign/timestamp=%v", preset.options.codesign_timestamp)
    fmt.sbprintfln(&sb, "codesign/timestamp_server_url=%q", preset.options.codesign_timestamp_server_url)
    fmt.sbprintfln(&sb, "codesign/digest_algorithm=%d", preset.options.codesign_digest_algorithm)
    fmt.sbprintfln(&sb, "codesign/description=%q", preset.options.codesign_description)
    serialize_packed_string_array(&sb, "codesign/custom_options", preset.options.codesign_custom_options)

    fmt.sbprintfln(&sb, "application/modify_resources=%v", preset.options.application_modify_resources)
    fmt.sbprintfln(&sb, "application/icon=%q", preset.options.application_icon)
    fmt.sbprintfln(&sb, "application/console_wrapper_icon=%q", preset.options.application_console_wrapper_icon)
    fmt.sbprintfln(&sb, "application/icon_interpolation=%d", preset.options.application_icon_interpolation)
    fmt.sbprintfln(&sb, "application/file_version=%q", preset.options.application_file_version)
    fmt.sbprintfln(&sb, "application/product_version=%q", preset.options.application_product_version)
    fmt.sbprintfln(&sb, "application/company_name=%q", preset.options.application_company_name)
    fmt.sbprintfln(&sb, "application/product_name=%q", preset.options.application_product_name)
    fmt.sbprintfln(&sb, "application/file_description=%q", preset.options.application_file_description)
    fmt.sbprintfln(&sb, "application/copyright=%q", preset.options.application_copyright)
    fmt.sbprintfln(&sb, "application/trademarks=%q", preset.options.application_trademarks)
    fmt.sbprintfln(&sb, "application/export_angle=%d", preset.options.application_export_angle)
    fmt.sbprintfln(&sb, "application/export_d3d12=%d", preset.options.application_export_d3d12)
    fmt.sbprintfln(&sb, "application/d3d12_agility_sdk_multiarch=%v", preset.options.application_d3d12_agility_sdk_multiarch)

    fmt.sbprintfln(&sb, "ssh_remote_deploy/enabled=%v", preset.options.ssh_remote_deploy_enabled)
    fmt.sbprintfln(&sb, "ssh_remote_deploy/host=%q", preset.options.ssh_remote_deploy_host)
    fmt.sbprintfln(&sb, "ssh_remote_deploy/port=%q", preset.options.ssh_remote_deploy_port)
    fmt.sbprintfln(&sb, "ssh_remote_deploy/extra_args_ssh=%q", preset.options.ssh_remote_deploy_extra_args_ssh)
    fmt.sbprintfln(&sb, "ssh_remote_deploy/extra_args_scp=%q", preset.options.ssh_remote_deploy_extra_args_scp)
    fmt.sbprintfln(&sb, "ssh_remote_deploy/run_script=%q", preset.options.ssh_remote_deploy_run_script)
    fmt.sbprintfln(&sb, "ssh_remote_deploy/cleanup_script=%q", preset.options.ssh_remote_deploy_cleanup_script)

    // loop through addon settings and append line by line

    return strings.to_string(sb)
}

@(private = "file")
serialize_packed_string_array :: proc(sb: ^strings.Builder, key: string, values: []string) {
    fmt.sbprintf(sb, "%s=PackedStringArray(", key)

    for value, i in values {
        if i > 0 {
            fmt.sbprint(sb, ", ")
        }

        fmt.sbprintf(sb, "%q", value)
    }

    fmt.sbprint(sb, ")\n")
}

@(private = "file")
register_api :: proc(L: ^lua.State) {
    lua.register(L, "set_name", lua_set_name)
    lua.register(L, "set_platform", lua_set_platform)
    lua.register(L, "set_runnable", lua_set_runnable)
    lua.register(L, "set_dedicated_server", lua_set_dedicated_server)
    lua.register(L, "set_custom_features", lua_set_custom_features)
    lua.register(L, "set_export_filter", lua_set_export_filter)
    lua.register(L, "set_export_files", lua_set_export_files)
    lua.register(L, "set_include_filter", lua_set_include_filter)
    lua.register(L, "set_exclude_filter", lua_set_exclude_filter)
    lua.register(L, "set_export_path", lua_set_export_path)
    lua.register(L, "set_patches", lua_set_patches)
    lua.register(L, "set_patch_delta_encoding", lua_set_patch_delta_encoding)
    lua.register(L, "set_patch_delta_compression_level_zstd", lua_set_patch_delta_compression_level_zstd)
    lua.register(L, "set_patch_delta_min_reduction", lua_set_patch_delta_min_reduction)
    lua.register(L, "set_patch_delta_include_filters", lua_set_patch_delta_include_filters)
    lua.register(L, "set_patch_delta_exclude_filters", lua_set_patch_delta_exclude_filters)
    lua.register(L, "set_encryption_include_filters", lua_set_encryption_include_filters)
    lua.register(L, "set_encryption_exclude_filters", lua_set_encryption_exclude_filters)
    lua.register(L, "set_seed", lua_set_seed)
    lua.register(L, "set_encrypt_pck", lua_set_encrypt_pck)
    lua.register(L, "set_encrypt_directory", lua_set_encrypt_directory)
    lua.register(L, "set_script_export_mode", lua_set_script_export_mode)
    lua.register(L, "set_custom_template_debug", lua_set_custom_template_debug)
    lua.register(L, "set_custom_template_release", lua_set_custom_template_release)
    lua.register(L, "set_debug_export_console_wrapper", lua_set_debug_export_console_wrapper)
    lua.register(L, "set_binary_format_embed_pck", lua_set_binary_format_embed_pck)
    lua.register(L, "set_texture_format_s3tc_bptc", lua_set_texture_format_s3tc_bptc)
    lua.register(L, "set_texture_format_etc2_astc", lua_set_texture_format_etc2_astc)
    lua.register(L, "set_shader_baker_enabled", lua_set_shader_baker_enabled)
    lua.register(L, "set_binary_format_architecture", lua_set_binary_format_architecture)
    lua.register(L, "set_codesign_enable", lua_set_codesign_enable)
    lua.register(L, "set_codesign_timestamp", lua_set_codesign_timestamp)
    lua.register(L, "set_codesign_timestamp_server_url", lua_set_codesign_timestamp_server_url)
    lua.register(L, "set_codesign_digest_algorithm", lua_set_codesign_digest_algorithm)
    lua.register(L, "set_codesign_description", lua_set_codesign_description)
    lua.register(L, "set_codesign_custom_options", lua_set_codesign_custom_options)
    lua.register(L, "set_application_modify_resources", lua_set_application_modify_resources)
    lua.register(L, "set_application_icon", lua_set_application_icon)
    lua.register(L, "set_application_console_wrapper_icon", lua_set_application_console_wrapper_icon)
    lua.register(L, "set_application_icon_interpolation", lua_set_application_icon_interpolation)
    lua.register(L, "set_application_file_version", lua_set_application_file_version)
    lua.register(L, "set_application_product_version", lua_set_application_product_version)
    lua.register(L, "set_application_company_name", lua_set_application_company_name)
    lua.register(L, "set_application_product_name", lua_set_application_product_name)
    lua.register(L, "set_application_file_description", lua_set_application_file_description)
    lua.register(L, "set_application_copyright", lua_set_application_copyright)
    lua.register(L, "set_application_trademarks", lua_set_application_trademarks)
    lua.register(L, "set_application_export_angle", lua_set_application_export_angle)
    lua.register(L, "set_application_export_d3d12", lua_set_application_export_d3d12)
    lua.register(L, "set_application_d3d12_agility_sdk_multiarch", lua_set_application_d3d12_agility_sdk_multiarch)
    lua.register(L, "set_ssh_remote_deploy_enabled", lua_set_ssh_remote_deploy_enabled)
    lua.register(L, "set_ssh_remote_deploy_host", lua_set_ssh_remote_deploy_host)
    lua.register(L, "set_ssh_remote_deploy_port", lua_set_ssh_remote_deploy_port)
    lua.register(L, "set_ssh_remote_deploy_extra_args_ssh", lua_set_ssh_remote_deploy_extra_args_ssh)
    lua.register(L, "set_ssh_remote_deploy_extra_args_scp", lua_set_ssh_remote_deploy_extra_args_scp)
    lua.register(L, "set_ssh_remote_deploy_run_script", lua_set_ssh_remote_deploy_run_script)
    lua.register(L, "set_ssh_remote_deploy_cleanup_script", lua_set_ssh_remote_deploy_cleanup_script)
}

// for lua to add custom settings for addons, a more generic function for setting key value pairs
// should be accessible. set_bool("imgui/debug", false), set_string, set_int, set_array ..

// TODO: check for verbose arg
export_preset_hook :: proc(args: ^models.Args, cfg: ^models.Config) {
    L: ^lua.State
    L = lua.L_newstate()

    lua.L_openlibs(L) // add standard libs to lua script

    ep: ^ExportPreset = new(ExportPreset)
    set_default_preset(ep)
    defer free(ep)
    logger.info(.CONFIG, fmt.tprint("export preset defaults"))

    register_api(L)
    logger.info(.CONFIG, fmt.tprint("lua api"))

    lua.L_dofile(L, strings.clone_to_cstring(args.script))

    lua.getglobal(L, "export_preset")
    if !lua.isfunction(L, -1) {
        lua.pop(L, 1)
        lua.close(L)
        logger.fatal(.CONFIG, fmt.tprintf("No 'export_preset' function found in %s. Will use default export presets", args.script))
    
    } else {
        // Call the function
        lua.pushlightuserdata(L, rawptr(ep))
        if lua.pcall(L, 1, 0, 0) != 0 {
            err_msg := lua.tostring(L, -1)
            logger.error(.SCRIPT, strings.clone_from_cstring(err_msg))
            fmt.println("Lua err: ", err_msg)
            lua.pop(L, 1)
        }
        logger.info(.CONFIG, fmt.tprint("called the function"))
    }

    ep_str: string = serialize(ep)
    defer delete(ep_str)

    preset_path, join_err := filepath.join({".", "export_presets.cfg"})
    if join_err != nil {
        logger.error(.CONFIG, fmt.tprintf("Cannot create file path for ./export_presets.cfg. Export presets will not be updated."))
        return
    }

    // Should probably listen for a result, and print if verbose
    write_file(ep_str, preset_path)
}

@(private = "file")
write_file :: proc(contents: string, path: string) {
    file, err := os.open(path, os.O_CREATE | os.O_WRONLY | os.O_TRUNC)
    if err != nil {
        return
    }
    defer os.close(file)

    num_bytes, err_write := os.write_string(file, contents)
    if err_write != nil {
        fmt.println("Error: Failed to write to file.") //
        return
    }
}

// TODO: add function for adding and excluding folder and files

lua_set_name :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    ep := (^ExportPreset)(lua.touserdata(L, 1))
    if ep != nil {
        ep.name = to_string(L, 2)
    }
    return 0
}

lua_set_platform :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    ep := (^ExportPreset)(lua.touserdata(L, 1))
    if ep != nil {
        ep.platform = to_string(L, 2)
    }
    return 0
}

lua_set_runnable :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    ep := (^ExportPreset)(lua.touserdata(L, 1))
    if ep != nil {
        ep.runnable = to_bool(L, 2)
    }
    return 0
}

lua_set_dedicated_server :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    ep := (^ExportPreset)(lua.touserdata(L, 1))
    if ep != nil {
        ep.dedicated_server = to_bool(L, 2)
    }
    return 0
}

lua_set_custom_features :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    ep := (^ExportPreset)(lua.touserdata(L, 1))
    if ep != nil {
        ep.custom_features = to_string(L, 2)
    }
    return 0
}

lua_set_export_filter :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    ep := (^ExportPreset)(lua.touserdata(L, 1))
    if ep != nil {
        ep.export_filter = to_string(L, 2)
    }
    return 0
}

lua_set_export_files :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    ep := (^ExportPreset)(lua.touserdata(L, 1))
    new_value := (^[]string)(lua.touserdata(L, 2))
    if ep != nil && new_value != nil {
        ep.export_files = new_value^
    }
    return 0
}

lua_set_include_filter :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    ep := (^ExportPreset)(lua.touserdata(L, 1))
    if ep != nil {
        ep.include_filter = to_string(L, 2)
    }
    return 0
}

lua_set_exclude_filter :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    ep := (^ExportPreset)(lua.touserdata(L, 1))
    if ep != nil {
        ep.exclude_filter = to_string(L, 2)
    }
    return 0
}

lua_set_export_path :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    ep := (^ExportPreset)(lua.touserdata(L, 1))
    if ep != nil {
        ep.export_path = to_string(L, 2)
    }
    return 0
}

lua_set_patches :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    ep := (^ExportPreset)(lua.touserdata(L, 1))
    new_value := (^[]string)(lua.touserdata(L, 2))
    if ep != nil && new_value != nil {
        ep.patches = new_value^
    }
    return 0
}

lua_set_patch_delta_encoding :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    ep := (^ExportPreset)(lua.touserdata(L, 1))
    if ep != nil {
        ep.patch_delta_encoding = to_bool(L, 2)
    }
    return 0
}

lua_set_patch_delta_compression_level_zstd :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    ep := (^ExportPreset)(lua.touserdata(L, 1))
    if ep != nil {
        ep.patch_delta_compression_level_zstd = int(lua.L_checkinteger(L, 2))
    }
    return 0
}

lua_set_patch_delta_min_reduction :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    ep := (^ExportPreset)(lua.touserdata(L, 1))
    if ep != nil {
        ep.patch_delta_min_reduction = to_f64(L, 2)
    }
    return 0
}

lua_set_patch_delta_include_filters :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    ep := (^ExportPreset)(lua.touserdata(L, 1))
    if ep != nil {
        ep.patch_delta_include_filters = to_string(L, 2)
    }
    return 0
}

lua_set_patch_delta_exclude_filters :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    ep := (^ExportPreset)(lua.touserdata(L, 1))
    if ep != nil {
        ep.patch_delta_exclude_filters = to_string(L, 2)
    }
    return 0
}

lua_set_encryption_include_filters :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    ep := (^ExportPreset)(lua.touserdata(L, 1))
    if ep != nil {
        ep.encryption_include_filters = to_string(L, 2)
    }
    return 0
}

lua_set_encryption_exclude_filters :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    ep := (^ExportPreset)(lua.touserdata(L, 1))
    if ep != nil {
        ep.encryption_exclude_filters = to_string(L, 2)
    }
    return 0
}

lua_set_seed :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    ep := (^ExportPreset)(lua.touserdata(L, 1))
    if ep != nil {
        ep.seed = to_int(L, 2)
    }
    return 0
}

lua_set_encrypt_pck :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    ep := (^ExportPreset)(lua.touserdata(L, 1))
    if ep != nil {
        ep.encrypt_pck = to_bool(L, 2)
    }
    return 0
}

lua_set_encrypt_directory :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    ep := (^ExportPreset)(lua.touserdata(L, 1))
    if ep != nil {
        ep.encrypt_directory = to_bool(L, 2)
    }
    return 0
}

lua_set_script_export_mode :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    ep := (^ExportPreset)(lua.touserdata(L, 1))
    if ep != nil {
        ep.script_export_mode = to_int(L, 2)
    }
    return 0
}

lua_set_custom_template_debug :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    ep := (^ExportPreset)(lua.touserdata(L, 1))
    if ep != nil && ep.options != nil {
        ep.options.custom_template_debug = to_string(L, 2)
    }
    return 0
}

lua_set_custom_template_release :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    ep := (^ExportPreset)(lua.touserdata(L, 1))
    if ep != nil && ep.options != nil {
        ep.options.custom_template_release = to_string(L, 2)
    }
    return 0
}

lua_set_debug_export_console_wrapper :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    ep := (^ExportPreset)(lua.touserdata(L, 1))
    if ep != nil && ep.options != nil {
        ep.options.debug_export_console_wrapper = to_int(L, 2)
    }
    return 0
}

lua_set_binary_format_embed_pck :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    ep := (^ExportPreset)(lua.touserdata(L, 1))
    if ep != nil && ep.options != nil {
        ep.options.binary_format_embed_pck = to_bool(L, 2)
    }
    return 0
}

lua_set_texture_format_s3tc_bptc :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    ep := (^ExportPreset)(lua.touserdata(L, 1))
    if ep != nil && ep.options != nil {
        ep.options.texture_format_s3tc_bptc = to_bool(L, 2)
    }
    return 0
}

lua_set_texture_format_etc2_astc :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    ep := (^ExportPreset)(lua.touserdata(L, 1))
    if ep != nil && ep.options != nil {
        ep.options.texture_format_etc2_astc = to_bool(L, 2)
    }
    return 0
}

lua_set_shader_baker_enabled :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    ep := (^ExportPreset)(lua.touserdata(L, 1))
    if ep != nil && ep.options != nil {
        ep.options.shader_baker_enabled = to_bool(L, 2)
    }
    return 0
}

lua_set_binary_format_architecture :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    ep := (^ExportPreset)(lua.touserdata(L, 1))
    if ep != nil && ep.options != nil {
        ep.options.binary_format_architecture = to_string(L, 2)
    }
    return 0
}

lua_set_codesign_enable :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    ep := (^ExportPreset)(lua.touserdata(L, 1))
    if ep != nil && ep.options != nil {
        ep.options.codesign_enable = to_bool(L, 2)
    }
    return 0
}

lua_set_codesign_timestamp :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    ep := (^ExportPreset)(lua.touserdata(L, 1))
    if ep != nil && ep.options != nil {
        ep.options.codesign_timestamp = to_bool(L, 2)
    }
    return 0
}

lua_set_codesign_timestamp_server_url :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    ep := (^ExportPreset)(lua.touserdata(L, 1))
    if ep != nil && ep.options != nil {
        ep.options.codesign_timestamp_server_url = to_string(L, 2)
    }
    return 0
}

lua_set_codesign_digest_algorithm :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    ep := (^ExportPreset)(lua.touserdata(L, 1))
    if ep != nil && ep.options != nil {
        ep.options.codesign_digest_algorithm = to_int(L, 2)
    }
    return 0
}

lua_set_codesign_description :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    ep := (^ExportPreset)(lua.touserdata(L, 1))
    if ep != nil && ep.options != nil {
        ep.options.codesign_description = to_string(L, 2)
    }
    return 0
}

lua_set_codesign_custom_options :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    ep := (^ExportPreset)(lua.touserdata(L, 1))
    new_value := (^[]string)(lua.touserdata(L, 2))
    if ep != nil && ep.options != nil && new_value != nil {
        ep.options.codesign_custom_options = new_value^
    }
    return 0
}

lua_set_application_modify_resources :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    ep := (^ExportPreset)(lua.touserdata(L, 1))
    if ep != nil && ep.options != nil {
        ep.options.application_modify_resources = to_bool(L, 2)
    }
    return 0
}

lua_set_application_icon :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    ep := (^ExportPreset)(lua.touserdata(L, 1))
    if ep != nil && ep.options != nil {
        ep.options.application_icon = to_string(L, 2)
    }
    return 0
}

lua_set_application_console_wrapper_icon :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    ep := (^ExportPreset)(lua.touserdata(L, 1))
    if ep != nil && ep.options != nil {
        ep.options.application_console_wrapper_icon = to_string(L, 2)
    }
    return 0
}

lua_set_application_icon_interpolation :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    ep := (^ExportPreset)(lua.touserdata(L, 1))
    if ep != nil && ep.options != nil {
        ep.options.application_icon_interpolation = to_int(L, 2)
    }
    return 0
}

lua_set_application_file_version :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    ep := (^ExportPreset)(lua.touserdata(L, 1))
    if ep != nil && ep.options != nil {
        ep.options.application_file_version = to_string(L, 2)
    }
    return 0
}

lua_set_application_product_version :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    ep := (^ExportPreset)(lua.touserdata(L, 1))
    if ep != nil && ep.options != nil {
        ep.options.application_product_version = to_string(L, 2)
    }
    return 0
}

lua_set_application_company_name :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    ep := (^ExportPreset)(lua.touserdata(L, 1))
    if ep != nil && ep.options != nil {
        ep.options.application_company_name = to_string(L, 2)
    }
    return 0
}

lua_set_application_product_name :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    ep := (^ExportPreset)(lua.touserdata(L, 1))
    if ep != nil && ep.options != nil {
        ep.options.application_product_name = to_string(L, 2)
    }
    return 0
}

lua_set_application_file_description :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    ep := (^ExportPreset)(lua.touserdata(L, 1))
    if ep != nil && ep.options != nil {
        ep.options.application_file_description = to_string(L, 2)
    }
    return 0
}

lua_set_application_copyright :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    ep := (^ExportPreset)(lua.touserdata(L, 1))
    if ep != nil && ep.options != nil {
        ep.options.application_copyright = to_string(L, 2)
    }
    return 0
}

lua_set_application_trademarks :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    ep := (^ExportPreset)(lua.touserdata(L, 1))
    if ep != nil && ep.options != nil {
        ep.options.application_trademarks = to_string(L, 2)
    }
    return 0
}

lua_set_application_export_angle :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    ep := (^ExportPreset)(lua.touserdata(L, 1))
    if ep != nil && ep.options != nil {
        ep.options.application_export_angle = to_int(L, 2)
    }
    return 0
}
lua_set_application_export_d3d12 :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    ep := (^ExportPreset)(lua.touserdata(L, 1))
    if ep != nil && ep.options != nil {
        ep.options.application_export_d3d12 = to_int(L, 2)
    }
    return 0
}

lua_set_application_d3d12_agility_sdk_multiarch :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    ep := (^ExportPreset)(lua.touserdata(L, 1))
    if ep != nil && ep.options != nil {
        ep.options.application_d3d12_agility_sdk_multiarch = to_bool(L, 2)
    }
    return 0
}

lua_set_ssh_remote_deploy_enabled :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    ep := (^ExportPreset)(lua.touserdata(L, 1))
    if ep != nil && ep.options != nil {
        ep.options.ssh_remote_deploy_enabled = to_bool(L, 2)
    }
    return 0
}

lua_set_ssh_remote_deploy_host :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    ep := (^ExportPreset)(lua.touserdata(L, 1))
    if ep != nil && ep.options != nil {
        ep.options.ssh_remote_deploy_host = to_string(L, 2)
    }
    return 0
}

lua_set_ssh_remote_deploy_port :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    ep := (^ExportPreset)(lua.touserdata(L, 1))
    if ep != nil && ep.options != nil {
        ep.options.ssh_remote_deploy_port = to_string(L, 2)
    }
    return 0
}

lua_set_ssh_remote_deploy_extra_args_ssh :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    ep := (^ExportPreset)(lua.touserdata(L, 1))
    if ep != nil && ep.options != nil {
        ep.options.ssh_remote_deploy_extra_args_ssh = to_string(L, 2)
    }
    return 0
}

lua_set_ssh_remote_deploy_extra_args_scp :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    ep := (^ExportPreset)(lua.touserdata(L, 1))
    if ep != nil && ep.options != nil {
        ep.options.ssh_remote_deploy_extra_args_scp = to_string(L, 2)
    }
    return 0
}

lua_set_ssh_remote_deploy_run_script :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    ep := (^ExportPreset)(lua.touserdata(L, 1))
    if ep != nil && ep.options != nil {
        ep.options.ssh_remote_deploy_run_script = to_string(L, 2)
    }
    return 0
}

lua_set_ssh_remote_deploy_cleanup_script :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    ep := (^ExportPreset)(lua.touserdata(L, 1))
    if ep != nil && ep.options != nil {
        ep.options.ssh_remote_deploy_cleanup_script = to_string(L, 2)
    }
    return 0
}
