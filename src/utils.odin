package main

import lua "vendor:lua/5.4"

to_bool :: proc(L: ^lua.State, arg: i32) -> bool {
    return lua.toboolean(L, arg) != false
}

to_string :: proc(L: ^lua.State, arg: i32) -> string {
    return string(lua.L_checkstring(L, arg))
}

to_string_arr :: proc(L: ^lua.State, arg: i32) -> ^[]string {
    return (^[]string)(lua.touserdata(L, arg))
}

to_int :: proc(L: ^lua.State, arg: i32) -> int {
    return int(lua.L_checkinteger(L, arg))
}

to_f64 :: proc(L: ^lua.State, arg: i32) -> f64 {
    return f64(lua.L_checknumber(L, arg))
}
