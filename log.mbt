///|
pub enum LogLevel {
  Off
  Info
  Debug
} derive(Eq)

///|
priv struct LogState {
  mut level : LogLevel
}

///|
let log_state : LogState = { level: Off }

///|
pub fn set_log_level(level : LogLevel) -> Unit {
  log_state.level = level
}

///|
pub fn parse_log_level(value : String) -> LogLevel? {
  match value {
    "debug" => Some(Debug)
    "info" => Some(Info)
    _ => None
  }
}

///|
fn log_print(level : String, msg : String) -> Unit {
  println("[" + level + "] " + msg)
}

///|
fn LogLevel::log_level_is_info(self : LogLevel) -> Bool {
  match self {
    Info => true
    Debug => true
    Off => false
  }
}

///|
fn LogLevel::log_level_is_debug(self : LogLevel) -> Bool {
  self == Debug
}

///|
fn log_info(msg : String) -> Unit {
  @tracing.info(msg)
  if log_state.level.log_level_is_info() {
    log_print("INFO", msg)
  }
}

///|
fn log_debug(msg : String) -> Unit {
  @tracing.debug(msg)
  if log_state.level.log_level_is_debug() {
    log_print("DEBUG", msg)
  }
}
