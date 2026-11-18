package main

import "core:strings"
import "core:strconv"
import "core:fmt"

import l "logger"
import m "models"
import u "utils"

parse_version_string :: proc(v: ^m.Version, version_str: string) -> bool {
    version_clean := u.strip_whitespace(version_str)
    defer delete(version_clean)

    versions, err_parts := strings.split(version_clean, ".")
    // defer {
    //     for v in versions {
    //         delete(v)
    //     }
    //     delete(versions)
    // }
    
    if err_parts != nil {
        l.info(.CONFIG, fmt.tprintf("Cannot extract build type or mode from version string: %s", version_clean))
        return false
    }

    if len(versions) != 3 {
        l.info(.CONFIG, fmt.tprintf("Version is not formatted correctly [major].[minor].[build_num]: %s", version_clean))
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

    return true
}

print_version :: proc(v: ^m.Version) {
    u.table("| Version",
        {"major", v.major},
        {"minor", v.minor},
        {"build_num", v.build_num},
    )
}