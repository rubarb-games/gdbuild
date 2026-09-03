package main

import "core:fmt"
import "core:flags"
import "core:os"
import "core:path/filepath"
import strings "core:strings"
import lua "vendor:lua/5.4"

import "logger"

ExecArgs :: struct {
    dry: bool       `args:"name=dry"     usage:"A dry run will only build the application, and will not bump the version or build number, and will not distribute to any target platforms."`,
    // version (as string? major.minor, as int? ver_major, ver_minor) - use to manually bump the version. Otherwise only the build number will bump
    version: string `args:"name=version" usage:"Specify the version to set. If not specified, the last version will be used."`
    // platform: string - specify target platform. Danger! It will cause builds to get out of sync. Maybe it should demand a dry run? if out of sync builds are ok, then saving current version needs to specify platform
    // mode: string - dev, beta, release. defaults to dev
    // type: string - demo, full, dlc

    // flags can use bits, like this: platform=steam,gog,epic to specify a set of options
}

L: ^lua.State

main :: proc() {
    exec_args: ExecArgs

    // Set default before parsing
    // The defaults could be put in a config file, to allow for customizing per project
    exec_args.dry = true // default to a dry run to prevent accidentally distributing the build
    exec_args.version = "0.0" // on the first run, the cache will be populated with the default version. On subsequent runs, the default version will be overridden by the version from the cache

    err := flags.parse(&exec_args, os.args[1:])
    if err != nil {
        logger.fatal(.CONFIG, fmt.tprintf("Error parsing arguments: %v\n", err))
        stderr_stream := os.to_stream(os.stderr)
        flags.write_usage(stderr_stream, ExecArgs, os.args[0])
        os.exit(1)
    }

    L = lua.L_newstate()
    lua.L_openlibs(L)

    config_file, join_err := filepath.join({"./scripts/", "config.lua"})
    if join_err != nil {
        logger.fatal(.CONFIG, fmt.tprintf("Cannot join root directory with config.lua. Abort."))
        os.exit(1)
    }

    lua.L_dofile(L, strings.clone_to_cstring(config_file))

    lua.getglobal(L, "create_config")
    if !lua.isfunction(L, -1) {
		lua.pop(L, 1)
		lua.close(L)
		logger.fatal(.CONFIG, "No create_config function found in config.lua. Cannot continue. Or maybe?")
	}

    lua.call(L, 0, 1)

    // Use a terminal printing package to prettify the output of the config building
    fmt.printf("Dry: %t Version: %s", exec_args.dry, exec_args.version);


}
