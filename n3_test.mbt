///|
let n3_bin = "_build/native/release/build/cmd/main/main.exe"

///|
async test "01-hello" {
  let src = "n2-examples/01-hello"
  let dst = "_build/n3_e2e/01-hello"
  let root = @fs.realpath(".")
  let exe = root + "/" + n3_bin
  if @fs.exists(dst) {
    @fs.rmdir(dst, recursive=true)
  }
  copy_tree(src, dst)
  let code = @process.run(exe, [], inherit_env=true, cwd=dst)
  inspect(code, content="0")
  let combined_path = dst + "/combined.txt"
  inspect(
    @fs.read_file(combined_path).text(),
    content="Hello from Ninja Build System!\nHello from n2!\n",
  )
}

///|
async fn copy_tree(src : String, dst : String) -> Unit {
  @fs.mkdir(dst, permission=0o755, recursive=true)
  let entries = @fs.readdir(src, include_hidden=false, sort=true)
  for name in entries {
    let from = src + "/" + name
    let to = dst + "/" + name
    match @fs.kind(from, follow_symlink=false) {
      @fs.FileKind::Directory => copy_tree(from, to)
      @fs.FileKind::Regular => {
        let data = @fs.read_file(from)
        @fs.write_file(to, data, create=0o644)
      }
      _ => ()
    }
  }
}
