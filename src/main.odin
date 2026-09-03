package main

import "core:fmt"
import "core:flags"
import "core:os"

ExecArgs :: struct {
    dry: bool       `args:"name=dry"     usage:"A dry run will only build the application, and will not bump the version or build number, and will not distribute to any target platforms."`,
    // version (as string? major.minor, as int? ver_major, ver_minor) - use to manually bump the version. Otherwise only the build number will bump
    version: string `args:"name=version" usage:"Specify the version to set. If not specified, the last version will be used."`
    // platform: string - specify target platform. Danger! It will cause builds to get out of sync. Maybe it should demand a dry run? if out of sync builds are ok, then saving current version needs to specify platform
    // mode: string - dev, beta, release. defaults to dev
    // type: string - demo, full, dlc

    // flags can use bits, like this: platform=steam,gog,epic to specify a set of options
}

main :: proc() {
    exec_args: ExecArgs

    // Set default before parsing
    // The defaults could be put in a config file, to allow for customizing per project
    exec_args.dry = true // default to a dry run to prevent accidentally distributing the build
    exec_args.version = "0.0" // on the first run, the cache will be populated with the default version. On subsequent runs, the default version will be overridden by the version from the cache

    err := flags.parse(&exec_args, os.args[1:])
    if err != nil {
        fmt.eprintf("Error parsing arguments: %v\n", err)
        stderr_stream := os.to_stream(os.stderr)
        flags.write_usage(stderr_stream, ExecArgs, os.args[0])
        os.exit(1)
    }

    fmt.printf("Dry: %t Version: %s", exec_args.dry, exec_args.version);
}
