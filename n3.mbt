///| n3 - A Ninja build system implementation in MoonBit

///| Ported from n2 (https://github.com/nicholasbishop/nicholasbishop/n2)

///|
/// The main entry point for the n3 build system.
pub async fn run(args : Array[String]) -> Int {
  let (trace_enabled, log_level) = parse_args(args)
  if trace_enabled {
    @tracing.setup(stdout=false, chrome=Some("trace.json"))
  }
  set_log_level(log_level)
  let result = run_inner()
  @tracing.close()
  result
}

///|
async fn run_inner() -> Int {
  let ninja_input = parse_ninja_file()
  let state = read(ninja_input)
  let work = Work::new(state.graph)
  for file_id in state.default {
    work.want_file(file_id) |> ignore
  }
  work.run()
}

///|
fn parse_args(args : Array[String]) -> (Bool, LogLevel) raise {
  let mut trace_enabled = false
  let mut log_level = LogLevel::Off
  let mut i = 1
  while i < args.length() {
    let arg = args[i]
    if arg == "--trace" {
      trace_enabled = true
    } else if arg == "--debug-level" {
      i = i + 1
      if i >= args.length() {
        fail("--debug-level requires a value: debug|info")
      }
      log_level = parse_log_level_or_fail(args[i])
    } else if arg.has_prefix("--debug-level=") {
      let prefix = "--debug-level="
      let value = arg.substring(start=prefix.length())
      log_level = parse_log_level_or_fail(value)
    }
    i = i + 1
  }
  (trace_enabled, log_level)
}

///|
fn parse_log_level_or_fail(value : String) -> LogLevel raise {
  match parse_log_level(value) {
    Some(level) => level
    None => fail("invalid --debug-level: \{value}")
  }
}
