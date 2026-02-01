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
    log_info("run build " + build_id_to_string(id) + " cmd=" + cmdline)
    let result = @tracing.scope_async("build " + build_id_to_string(id), fn() {
      @process.run("sh", ["-c", cmdline])
    })
    log_info(
      "run done build " +
      build_id_to_string(id) +
      " result=" +
      result.to_string(),
    )
    self.results.put(FinishedTask::{ build_id: id, output: "", result })
    log_debug("queued result build " + build_id_to_string(id))
  })
}

///|
async fn Runner::wait(self : Runner) -> FinishedTask {
  let task = self.results.get()
  self.running -= 1
  task
}
