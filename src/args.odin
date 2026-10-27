package main

import "core:os"
import "core:fmt"
import "core:flags"
import "core:strings"
import lua "vendor:lua/5.4"

import m "models"
import l "logger"
import u "utils"

parse_args :: proc(args: ^m.Args) {
    err := flags.parse(args, os.args[1:])
    if err != nil {
        l.fatal(.CONFIG, fmt.tprintf("Error parsing arguments: %v\n", err))
        stderr_stream := os.to_stream(os.stderr)
        flags.write_usage(stderr_stream, m.Args, os.args[0])
        os.exit(1)
    }
}

validate_args :: proc(args: ^m.Args) -> bool {
    valid := true
    if script_path_abs, ok := u.get_absolute_path(args.script_path); !ok {
        l.fatal(.ARGS, fmt.tprintf("Cannot find main lua script at %s", args.script_path))
        valid = false
    }
    return valid
}

print_args :: proc(args: ^m.Args) {
    u.table("| Arguments",
        {"script_path", args.script_path},
        {"live", args.live},
        {"version", args.version},
        {"verbose", args.verbose},
    )
}
