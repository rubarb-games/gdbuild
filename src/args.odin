package main

import "core:os"
import "core:path/filepath"
import "core:fmt"
import "core:flags"

import m "models"
import l "logger"
import u "utils"

parse :: proc(args: ^m.Args) {
    err := flags.parse(args, os.args[1:])
    if err != nil {
        l.fatal(.CONFIG, fmt.tprintf("Error parsing arguments: %v\n", err))
        stderr_stream := os.to_stream(os.stderr)
        flags.write_usage(stderr_stream, m.Args, os.args[0])
        os.exit(1)
    }
}

print :: proc(args: ^m.Args) {
    u.table("| Arguments",
        {"script_path", args.script_path},
        {"live", args.live},
        {"version", args.version},
        {"verbose", args.verbose},
    )
}
