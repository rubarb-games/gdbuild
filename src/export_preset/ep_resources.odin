package export_preset

import "core:fmt"
import "core:os"
import "core:strings"
import "base:runtime"
import lua "vendor:lua/5.4"

import m "../models"
import l "../logger"
import u "../utils"

SCRIPT_EXPORT_MODE_TEXT :: 0
SCRIPT_EXPORT_MODE_BINARY_TOKENS :: 1
SCRIPT_EXPORT_MODE_COMPRESSED_BINARY_TOKENS :: 2

BINARY_ARCHITECTURE_X86_64 :: "x86_64"
BINARY_ARCHITECTURE_X86_32 :: "x86_32"
BINARY_ARCHITECTURE_ARM64 :: "arm64"

resources_api :: proc(L: ^lua.State) {
    lua.register(L, "script_export_mode", lua_set_script_export_mode)
    lua.register(L, "binary_format_embed_pck", lua_set_binary_format_embed_pck)
    lua.register(L, "texture_format_s3tc_bptc", lua_set_texture_format_s3tc_bptc)
    lua.register(L, "texture_format_etc2_astc", lua_set_texture_format_etc2_astc)
    lua.register(L, "shader_baker_enabled", lua_set_shader_baker_enabled)
    lua.register(L, "binary_format_architecture", lua_set_binary_format_architecture)
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
