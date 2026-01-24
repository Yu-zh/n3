///|
/// Id for File nodes in the Graph
pub struct FileId(Int) derive(Eq, Hash, Show)

///|
/// Id for Build nodes in the Graph
pub struct BuildId(Int) derive(Eq, Hash, Show)

///|
/// A single file referenced as part of a build
pub struct File {
  name : String
  mut input : BuildId? // The Build that generates this file, if any
  downstream : Array[BuildId] // Builds that depend on this file
}

///|
pub struct Build {
  cmdline : String?
  ins : Array[FileId]
  outs : Array[FileId]
}

///|
pub struct Graph {
  builds : Map[BuildId, Build]
  file_by_id : Map[FileId, File]
  file_by_name : Map[String, FileId]
} derive(Default)

///|
fn Graph::get_file_id(self : Graph, name : String) -> FileId {
  match self.file_by_name.get(name) {
    Some(id) => id
    None => {
      let id : FileId = self.file_by_id.length()
      self.file_by_name.set(name, id)
      self.file_by_id.set(id, File::{ name, input: None, downstream: [] })
      id
    }
  }
}

///|
fn Graph::add_build(self : Graph, b : Build) -> Unit {
  let build_id : BuildId = self.builds.length()
  // Set input relationship for output files
  for out_id in b.outs {
    let file = self.file_by_id.get(out_id).unwrap()
    file.input = Some(build_id)
  }
  // Add to downstream for input files
  for in_id in b.ins {
    let file = self.file_by_id.get(in_id).unwrap()
    file.downstream.push(build_id)
  }
  self.builds.set(build_id, b)
}
