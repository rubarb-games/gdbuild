package logger

import "core:fmt"
import "core:time"

dump_dir : string = ""

LogType :: enum {
	TRACE,   // Very detailed information (every file loaded, every function called)
	DEBUG,   // Useful during development
	INFO,    // Normal progress
	WARNING, // Something unexpected but recoverable
	ERROR,   // An operation failed
	FATAL,   // The project cannot continue
}

LogCategory :: enum {
	CONFIG,
	SCRIPT,
	REPO,
	ENGINE,
	PROJECT,
	PLATFORM,
    DISTRIBUTION,
}

LogEntry :: struct {
	timestamp : string,
	level : LogType,
	category: LogCategory,
	message : string
}

entries: [dynamic]LogEntry

log :: proc(level: LogType, category: LogCategory, message: string) {
    entry := LogEntry{
        timestamp = get_timestamp(),
        level = level,
        category = category,
        message = message,
    }

    append(&entries, entry)

    fmt.printfln("%s %s",
        colorize_tags(fmt.tprintf("[%s] [%s] [%s]", entry.timestamp, log_type_to_string(entry.level), log_category_to_string(entry.category)), level),
        colorize_msg(entry.message, level))
}

trace :: proc(category: LogCategory, message: string) { log(LogType.TRACE, category, message) }
debug :: proc(category: LogCategory, message: string) { log(LogType.DEBUG, category, message) }
info :: proc(category: LogCategory, message: string) { log(LogType.INFO, category, message) }
warning :: proc(category: LogCategory, message: string) { log(LogType.WARNING, category, message) }
error :: proc(category: LogCategory, message: string) { log(LogType.ERROR, category, message) }
fatal :: proc(category: LogCategory, message: string) { log(LogType.FATAL, category, message) }

@(private = "file")
colorize_tags :: proc(msg: string, log_type: LogType) -> string {
	switch log_type {
	case .TRACE: return white(msg)
	case .DEBUG: return white(msg)
	case .INFO: return green(msg)
	case .WARNING: return yellow(msg)
	case .ERROR: return red(msg)
	case .FATAL: return on_bright_red(msg)
	case: return white(msg)
	}
}

@(private = "file")
colorize_msg :: proc(msg: string, log_type: LogType) -> string {
	switch log_type {
	case .TRACE: return white(msg)
	case .DEBUG: return white(msg)
	case .INFO: return green(msg)
	case .WARNING: return yellow(msg)
	case .ERROR: return red(msg)
	case .FATAL: return bright_red(msg)
	case: return white(msg)
	}
}

get_timestamp :: proc() -> string {
	hour, minute, second := time.clock_from_time(time.now())
	return fmt.tprintf("%02d:%02d:%02d",
		hour,
		minute,
		second,
	)
}

log_type_to_string :: proc(t: LogType) -> string {
	switch t {
	case .TRACE:
		return "TRACE"
	case .DEBUG:
		return "DEBUG"
	case .INFO:
		return "INFO"
	case .WARNING:
		return "WARNING"
	case .ERROR:
		return "ERROR"
	case .FATAL:
		return "FATAL"
	}

	return "UNKNOWN"
}

log_category_to_string :: proc(t: LogCategory) -> string {
	switch t {
	case .CONFIG:
		return "CONFIG"
	case .SCRIPT:
		return "SCRIPT"
	case .REPO:
		return "REPO"
	case .ENGINE:
		return "ENGINE"
	case .PROJECT:
		return "PROJECT"
	case .PLATFORM:
		return "PLATFORM"
	case .DISTRIBUTION:
		return "DISTRIBUTION"
	}

	return "UNKNOWN"
}

// Dumps the log entries to a text file either in the current directory or the user's home directory.
// TODO: accept file path as arg
// TODO: add option to dump only certain categories to file
dump_log :: proc() {
	if dump_dir == "" {
		dump_dir = "Find a suitable directory to dump the log"
	}
}