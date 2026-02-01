///|
/// Build states go through this sequence
priv enum BuildState {
  Unknown // Default initial state
  Want // We want to ensure it's up to date but its dependencies are not yet ready
  Ready // Dependencies are up to date, ready to check whether it's dirty
  // Queued // Dirty and queued for building
  Running // Currently executing
  Done // Already up to date (not dirty) or finished successfully
  // Failed // Finished but failed
} derive(Eq)

///|
/// Work coordinates the build execution
priv struct Work {
  graph : Graph
  // TODO: build_states can be optimized to fixedarray
  build_states : Map[BuildId, BuildState]
  ready_queue : @deque.Deque[BuildId]
}

///|
fn Work::new(graph : Graph) -> Work {
  let build_states = Map::new()
  for p in graph.builds {
    let (build_id, _) = p
    build_states.set(build_id, Unknown)
  }
  { graph, build_states, ready_queue: @deque.Deque::new() }
}

///|
fn Work::set(self : Work, build_id : BuildId, state : BuildState) -> Unit {
  self.log(
    "set build " +
    build_id_to_string(build_id) +
    " -> " +
    build_state_to_string(state),
  )
  if self.build_states.get(build_id) is Some(Unknown) && state == Ready {
    self.ready_queue.push_back(build_id)
  }
  self.build_states.set(build_id, state)
}

///|
/// TODO: cycle detection
fn Work::want_build(self : Work, build_id : BuildId) -> BuildState raise {
  guard self.graph.builds.get(build_id) is Some(build)
  guard self.build_states.get(build_id) is Some(state)
  self.log(
    "want_build " +
    build_id_to_string(build_id) +
    " state=" +
    build_state_to_string(state),
  )
  if state != Unknown {
    return state
  }
  let mut ready = true
  for input in build.ins {
    if !self.want_file(input) {
      ready = false
    }
  }
  let state = if ready { Ready } else { Want }
  self.set(build_id, state)
  state
}

///|
/// TODO: cycle detection
fn Work::want_file(self : Work, file_id : FileId) -> Bool raise {
  guard self.graph.file_by_id.get(file_id) is Some(file) else {
    fail("unknown file id")
  }
  self.log("want_file " + file_id_to_string(file_id) + " name=" + file._name)
  if file.input is Some(build_id) {
    self.want_build(build_id) is Done
  } else {
    // Source file, always up to date
    true
  }
}

///|
async fn Work::run(self : Work) -> Int {
  let runner = Runner::new(8)
  @async.with_task_group(tg => {
    while self.has_ready() || runner.running > 0 {
      self.log(
        "loop ready=" +
        self.ready_queue.length().to_string() +
        " running=" +
        runner.running.to_string(),
      )
      while runner.can_run() {
        match self.ready_queue.pop_front() {
          None => break
          Some(ready_build) => {
            self.set(ready_build, Running)
            guard self.graph.builds.get(ready_build) is Some(build)
            let cmdline = match build.cmdline {
              Some(cmd) => cmd
              None => "<none>"
            }
            self.log(
              "start build " +
              build_id_to_string(ready_build) +
              " cmd=" +
              cmdline,
            )
            runner.start(tg, ready_build, build)
          }
        }
      }
      self.log("waiting for result; running=" + runner.running.to_string())
      let finished = runner.wait()
      self.log(
        "finished build " +
        build_id_to_string(finished.build_id) +
        " result=" +
        finished.result.to_string(),
      )
      self.set(finished.build_id, Done)
      guard finished.result is 0 else { return finished.result }
      ignore(finished.output)
      self.ready_dependents(finished.build_id)
    }
    return 0
  })
}

///|
fn Work::all_input_done(self : Work, build : BuildId) -> Bool {
  guard self.graph.builds.get(build) is Some(b)
  for input in b.ins {
    guard self.graph.file_by_id.get(input) is Some(input_file)
    match input_file.input {
      None => ()
      Some(input_build) =>
        if not(self.build_states.get(input_build) is Some(Done)) {
          return false
        }
    }
  }
  true
}

///|
fn Work::ready_dependents(self : Work, build_id : BuildId) -> Unit {
  guard self.graph.builds.get(build_id) is Some(build)
  for output in build.outs {
    guard self.graph.file_by_id.get(output) is Some(output_file)
    for d in output_file.downstream {
      if self.all_input_done(d) && self.build_states.get(d) is Some(Want) {
        self.set(d, Ready)
        self.ready_queue.push_back(d)
      }
    }
  }
}

///|
fn Work::has_ready(self : Work) -> Bool {
  !self.ready_queue.is_empty()
}

///|
fn Work::log(self : Work, msg : String) -> Unit {
  log_debug(msg)
}

///|
fn build_id_to_string(id : BuildId) -> String {
  let BuildId(i) = id
  i.to_string()
}

///|
fn file_id_to_string(id : FileId) -> String {
  let FileId(i) = id
  i.to_string()
}

///|
fn build_state_to_string(state : BuildState) -> String {
  match state {
    Unknown => "Unknown"
    Want => "Want"
    Ready => "Ready"
    Running => "Running"
    Done => "Done"
  }
}
