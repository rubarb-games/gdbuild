package models

Args :: struct {
    // Can create one script for every type (demo, full)
    script: string      `args:"pos=0"          usage:"Path to the build script. Defaults to ./scripts/main.lua"`,
    dry: bool           `args:"name=dry"       usage:"A dry run will only build the application, and will not bump the version or build number, and will not distribute to any target platforms."`,
    
    // For this to work, you either have to know what was the
    // last version, or first ask gdbuild to print the last
    // version.
    // Could maybe add three args for bumping the versions
    // bump_patch X -- bumps by X
    // bump_minor X -- bumps by X
    // bump_major X -- bumps by X
    // The rules:
    // - version digits are prioritized as major > minor > patch
    // - bumping any digit will also reset the lower ranking digits
    //   0.9.9 -> bump_major -> 1.0.0
    //   0.9.9 -> bump_major, bump_minor -> 1.1.0
    // - bumping more than one digit, will bump the higher ranking digits before bumping the lower
    version: string     `args:"name=version,v" usage:"Specify the version to set. If not specified, the last version will be used."`,
    verbose: bool       `args:"name=verbose"   usage:"Print all the details"`
}

