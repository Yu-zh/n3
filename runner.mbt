///|
priv struct FinishedTask {
  build_id : BuildId
  output : Bytes
  result : Int
}

///|
priv struct Runner {
  parallelism : Int
  mut running : Int
  results : @aqueue.Queue[FinishedTask]
}

///|
fn Runner::new(parallelism : Int) -> Runner {
  { parallelism, running: 0, results: @aqueue.Queue::new(kind=Unbounded) }
}

///|
fn Runner::can_run(self : Runner) -> Bool {
  self.running < self.parallelism
}

///|
fn Runner::start(
  self : Runner,
  group : @async.TaskGroup[Int],
  id : BuildId,
  build : Build,
) -> Unit {
  self.running += 1
  group.spawn_bg(fn() {
    let cmdline = match build.cmdline {
      Some(cmd) => cmd
      None => "<none>"
    }
    debug_log(
      "run build " + build_id_to_string(id) + " cmd=" + cmdline,
    )
    let result = @process.run("sh", ["-c", cmdline])
    debug_log(
      "run done build " + build_id_to_string(id) + " result=" +
      result.to_string(),
    )
    self.results.put(FinishedTask::{ build_id: id, output: "", result })
    debug_log("queued result build " + build_id_to_string(id))
  })
}

///|
async fn Runner::wait(self : Runner) -> FinishedTask {
  let task = self.results.get()
  self.running -= 1
  task
}
