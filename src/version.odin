package main

import "core:strings"
import "core:strconv"
import "core:fmt"

import l "logger"
import m "models"
import u "utils"

parse_version_string :: proc(v: ^m.Version, version_str: string) -> bool {
    parts, err_parts := strings.split(version_str, " ")
    if err_parts != nil {
        l.info(.CONFIG, fmt.tprintf("Cannot extract build type or mode from version string: %s", version_str))
        // could still look for version
        return false
    }

    if len(parts) != 3 {
        l.info(.CONFIG, fmt.tprintf("Expected a 3 part version string [version] [type] [mode]: %s", version_str))
        return false
    }

    versions, err_versions := strings.split(parts[0], ".")
    if err_versions != nil {
        l.info(.CONFIG, fmt.tprintf("Expected at least one . in the version: %s", parts[0]))
        return false
    }

    if len(versions) != 3 {
        l.info(.CONFIG, fmt.tprintf("Version is not formatted correctly [major].[minor].[build_num]: %s", parts[0]))
        return false
    }

    if major, ok := strconv.parse_int(versions[0]); ok {
        v.major = major
    }
    if minor, ok := strconv.parse_int(versions[1]); ok {
        v.minor = minor
    }
    if build_num, ok := strconv.parse_int(versions[2]); ok {
        v.build_num = build_num
    }

    v.build_type = parts[1]
    v.build_mode = parts[2]

    return true
}

print_version :: proc(v: ^m.Version) {
    u.table("| Version",
        {"major", v.major},
        {"minor", v.minor},
        {"build_num", v.build_num},
        {"build_type", v.build_type},
        {"build_mode", v.build_mode},
    )
}