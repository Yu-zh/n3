///|
let debug_enabled = true

///|
fn debug_log(msg : String) -> Unit {
  if debug_enabled {
    println("[n3] " + msg)
  }
}
