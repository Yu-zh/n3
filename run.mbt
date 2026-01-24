///|
/// The main entry point for the n3 build system.
pub async fn run() -> Int {
  let ninja_input = parse_ninja_file()
  let state = read(ninja_input)
  let work = Work::new(state.graph)
  for file_id in state.default {
    work.want_file(file_id) |> ignore
  }
  work.run()
}
