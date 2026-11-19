package export_preset

import "core:fmt"
import "core:os"
import "core:strings"
import "base:runtime"
import lua "vendor:lua/5.4"

import m "../models"
import l "../logger"
import u "../utils"

CONSOLE_WRAPPER_NO                :: 0
CONSOLE_WRAPPER_DEBUG_ONLY        :: 1
CONSOLE_WRAPPER_DEBUG_AND_RELEASE :: 2

debug_api :: proc(L: ^lua.State) {
    lua.register(L, "export_console_wrapper", lua_set_export_console_wrapper)
}

lua_set_export_console_wrapper :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    if s, ok := u.get_string(L, 1); ok {
        switch s {
            case "no":
                ep.options.debug_export_console_wrapper = CONSOLE_WRAPPER_NO
            case "debug_only":
                ep.options.debug_export_console_wrapper = CONSOLE_WRAPPER_DEBUG_ONLY
            case "debug_and_release":
                ep.options.debug_export_console_wrapper = CONSOLE_WRAPPER_DEBUG_AND_RELEASE
            case:
                l.error(.EXPORT_PRESET, fmt.tprintf("Invalid option for export_console_wrapper: %s", s))
                return 1
        }
    }
    return 0
}
