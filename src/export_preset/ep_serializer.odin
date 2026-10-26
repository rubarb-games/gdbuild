package export_preset

import "core:strings"
import "core:fmt"
import "core:os"

import m "../models"

main :: proc() {}

serialize :: proc(preset: ^m.ExportPreset) -> string {
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
serialize_packed_string_array :: proc(sb: ^strings.Builder, key: string, values: [dynamic]string) {
    fmt.sbprintf(sb, "%s=PackedStringArray(", key)

    for value, i in values {
        if i > 0 {
            fmt.sbprint(sb, ", ")
        }

        fmt.sbprintf(sb, "%q", value)
    }

    fmt.sbprint(sb, ")\n")
}

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
