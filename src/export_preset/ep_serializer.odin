package export_preset

import "core:strings"
import "core:fmt"
import "core:os"

import m "../models"
import l "../logger"

main :: proc() {}

write_string :: proc(sb: ^strings.Builder, value: string) {
    strings.write_string(sb, fmt.tprintln(value))
}

write_stringf :: proc(sb: ^strings.Builder, format: string, values: ..any) {
    strings.write_string(sb, fmt.tprintfln(format, ..values))
}

serialize :: proc(preset: ^m.ExportPreset, sb: ^strings.Builder) {
    write_string(sb, "[preset.0]")

    write_stringf(sb, "name=%q", ep.name)
    write_stringf(sb, "platform=%q", preset.platform)
    write_stringf(sb, "runnable=%v", preset.runnable)
    write_stringf(sb, "dedicated_server=%v", preset.dedicated_server)
    write_stringf(sb, "custom_features=%q", preset.custom_features)
    write_stringf(sb, "export_path=%q", preset.export_path)

    // exclude: exclude the ones on export_files
    // all_resources: export all, ignores files in export_files
    // scens: certain scenes and all dependencies
    // resources: selected resources and deps
    // customized: as dedicated server
    // - dedicated_server = true
    // - customized_files={"res://":"strip"} (export_files is not even serialized)
    write_stringf(sb, "export_filter=%q", preset.export_filter)  
    write_stringf(sb, "include_filter=%q", preset.include_filter)
    write_stringf(sb, "exclude_filter=%q", preset.exclude_filter)
    serialize_packed_string_array(sb, "export_files", preset.export_files)

    serialize_packed_string_array(sb, "patches", preset.patches)
    write_stringf(sb, "patch_delta_encoding=%v", preset.patch_delta_encoding)
    write_stringf(sb, "patch_delta_compression_level_zstd=%d", preset.patch_delta_compression_level_zstd)
    write_stringf(sb, "patch_delta_min_reduction=%g", preset.patch_delta_min_reduction)
    write_stringf(sb, "patch_delta_include_filters=%q", preset.patch_delta_include_filters)
    write_stringf(sb, "patch_delta_exclude_filters=%q", preset.patch_delta_exclude_filters)

    write_stringf(sb, "encryption_include_filters=%q", preset.encryption_include_filters)
    write_stringf(sb, "encryption_exclude_filters=%q", preset.encryption_exclude_filters)
    write_stringf(sb, "encrypt_pck=%v", preset.encrypt_pck)
    write_stringf(sb, "encrypt_directory=%v", preset.encrypt_directory)
    write_stringf(sb, "seed=%d", preset.seed)

    // Use an enum instead? How does that work with Lua?
    // fmt.sbprintfln(&sb, "script_export_mode=%d", preset.script_export_mode)

    // Export Preset Options

    write_string(sb, "")
    write_string(sb, "[preset.0.options]")

    write_stringf(sb, "custom_template/debug=%q", preset.options.custom_template_debug)
    write_stringf(sb, "custom_template/release=%q", preset.options.custom_template_release)

    write_stringf(sb, "debug/export_console_wrapper=%d", preset.options.debug_export_console_wrapper)

    write_stringf(sb, "binary_format/embed_pck=%v", preset.options.binary_format_embed_pck)
    write_stringf(sb, "binary_format/architecture=%q", preset.options.binary_format_architecture)

    write_stringf(sb, "texture_format/s3tc_bptc=%v", preset.options.texture_format_s3tc_bptc)
    write_stringf(sb, "texture_format/etc2_astc=%v", preset.options.texture_format_etc2_astc)

    write_stringf(sb, "shader_baker/enabled=%v", preset.options.shader_baker_enabled)

    // fmt.sbprintfln(&sb, "codesign/enable=%v", preset.options.codesign_enable)
    // fmt.sbprintfln(&sb, "codesign/timestamp=%v", preset.options.codesign_timestamp)
    // fmt.sbprintfln(&sb, "codesign/timestamp_server_url=%q", preset.options.codesign_timestamp_server_url)
    // fmt.sbprintfln(&sb, "codesign/digest_algorithm=%d", preset.options.codesign_digest_algorithm)
    // fmt.sbprintfln(&sb, "codesign/description=%q", preset.options.codesign_description)
    // serialize_packed_string_array(&sb, "codesign/custom_options", preset.options.codesign_custom_options)

    write_stringf(sb, "application/modify_resources=%v", preset.options.application_modify_resources)
    write_stringf(sb, "application/icon=%q", preset.options.application_icon)
    write_stringf(sb, "application/console_wrapper_icon=%q", preset.options.application_console_wrapper_icon)
    write_stringf(sb, "application/icon_interpolation=%d", preset.options.application_icon_interpolation)
    write_stringf(sb, "application/file_version=%q", preset.options.application_file_version)
    write_stringf(sb, "application/product_version=%q", preset.options.application_product_version)
    write_stringf(sb, "application/company_name=%q", preset.options.application_company_name)
    write_stringf(sb, "application/product_name=%q", preset.options.application_product_name)
    write_stringf(sb, "application/file_description=%q", preset.options.application_file_description)
    write_stringf(sb, "application/copyright=%q", preset.options.application_copyright)
    write_stringf(sb, "application/trademarks=%q", preset.options.application_trademarks)
    write_stringf(sb, "application/export_angle=%d", preset.options.application_export_angle)
    write_stringf(sb, "application/export_d3d12=%d", preset.options.application_export_d3d12)
    write_stringf(sb, "application/d3d12_agility_sdk_multiarch=%v", preset.options.application_d3d12_agility_sdk_multiarch)

    // fmt.sbprintfln(&sb, "ssh_remote_deploy/enabled=%v", preset.options.ssh_remote_deploy_enabled)
    // fmt.sbprintfln(&sb, "ssh_remote_deploy/host=%q", preset.options.ssh_remote_deploy_host)
    // fmt.sbprintfln(&sb, "ssh_remote_deploy/port=%q", preset.options.ssh_remote_deploy_port)
    // fmt.sbprintfln(&sb, "ssh_remote_deploy/extra_args_ssh=%q", preset.options.ssh_remote_deploy_extra_args_ssh)
    // fmt.sbprintfln(&sb, "ssh_remote_deploy/extra_args_scp=%q", preset.options.ssh_remote_deploy_extra_args_scp)
    // fmt.sbprintfln(&sb, "ssh_remote_deploy/run_script=%q", preset.options.ssh_remote_deploy_run_script)
    // fmt.sbprintfln(&sb, "ssh_remote_deploy/cleanup_script=%q", preset.options.ssh_remote_deploy_cleanup_script)

    // loop through addon settings and append line by line
}

@(private = "file")
serialize_packed_string_array :: proc(sb: ^strings.Builder, key: string, values: [dynamic]string) {
    strings.write_string(sb, fmt.tprintf("%s=PackedStringArray(", key))
    for value, i in values {
        if i > 0 {
            strings.write_string(sb, ", ")
        }
        strings.write_string(sb, fmt.tprintf("%q", value))
    }
    strings.write_string(sb, ")\n")
}

write_file :: proc(ep: ^m.ExportPreset, path: string) {
    file, err_file := os.open(path, os.O_CREATE | os.O_WRONLY | os.O_TRUNC)
    if err_file != nil {
        l.fatal(.EXPORT_PRESET, fmt.tprintf("Cannot create export preset at %s", path))
        return
    }
    defer os.close(file)

    sb: strings.Builder
    strings.builder_init(&sb)
    defer strings.builder_destroy(&sb)

    serialize(ep, &sb)
    
    file_content := strings.to_string(sb)

    _, err_bytes := os.write_string(file, file_content)
    if err_bytes != nil {
        l.warning(.EXPORT_PRESET, fmt.tprintf("Could not create export preset at: %s", path))
        return
    }

    l.info(.EXPORT_PRESET, fmt.tprintf("Created export preset at '%s'", path))
}
