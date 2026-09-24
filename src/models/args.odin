package models

Args :: struct {
    script_path: string `args:"pos=0"          usage:"Path to the main script. Defaults to scripts/main.lua"`,
    dry: bool           `args:"name=dry"       usage:"A dry run will only build the application, and will not bump the version or build number, and will not distribute to any target platforms."`,
    version: string     `args:"name=version,v" usage:"Specify the version to set. If not specified, the last version will be used."`,
    verbose: bool       `args:"name=verbose"   usage:"Print all the details"`
    // platform: string - specify target platform. Danger! It will cause builds to get out of sync. Maybe it should demand a dry run? if out of sync builds are ok, then saving current version needs to specify platform
    // mode: string - dev, beta, release. defaults to dev
    // type: string - demo, full, dlc

    // flags can use bits, like this: platform=steam,gog,epic to specify a set of options
}

