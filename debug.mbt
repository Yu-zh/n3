///|
let debug_enabled = false

///|
fn debug_log(msg : String) -> Unit {
  if debug_enabled {
    println("[n3] " + msg)
  }
}
