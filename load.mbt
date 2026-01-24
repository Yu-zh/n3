///|
/// Worker that parses .ninja files and constructs the graph
pub struct Loader {
  graph : Graph
  default : Array[FileId]
  rules : Map[Bytes, Map[String, EvalString]]
} derive(Default)

///|
/// Result of the loader's work
pub struct State {
  graph : Graph
  default : Array[FileId]
}

///|
/// Convert Bytes (ASCII/UTF-8) to String
fn bytes_to_string(b : Bytes) -> String {
  let buf = StringBuilder::new()
  for i in 0..<b.length() {
    buf.write_char(b[i].to_int().unsafe_to_char())
  }
  buf.to_string()
}

///|
/// Parse space-separated paths from bytes
fn parse_paths(input : Bytes) -> Array[String] {
  let paths : Array[String] = []
  let s = bytes_to_string(input).trim(chars=" \t")
  if s.is_empty() {
    return paths
  }
  for part in s.split(" ") {
    let p = part.trim(chars=" \t")
    if not(p.is_empty()) {
      paths.push(p.to_string())
    }
  }
  paths
}

///|
fn read(stmts : Array[Statement]) -> State {
  let loader = Loader::default()
  // Pre-register phony rule
  loader.rules.set(b"phony", {})
  for stmt in stmts {
    match stmt {
      RuleStmt({ name, vars }) => {
        let varlist : Map[String, EvalString] = {}
        for p in vars {
          let (k, v) = p
          varlist.set(bytes_to_string(k), EvalString::from_bytes(v))
        }
        loader.rules.set(name, varlist)
      }
      BuildStmt({ rule, outs, ins, vars }) => {
        // 1. Parse file paths
        let out_paths = parse_paths(outs)
        let in_paths = parse_paths(ins)
        // 2. Convert to FileIds
        let out_ids = out_paths.map(fn(p) { loader.graph.get_file_id(p) })
        let in_ids = in_paths.map(fn(p) { loader.graph.get_file_id(p) })
        // 3. Look up rule
        let rule_vars = loader.rules.get(rule).unwrap_or({})
        // 4. Build environments for lookup
        let build_vars : Map[String, EvalString] = {}
        for p in vars {
          let (k, v) = p
          build_vars.set(bytes_to_string(k), EvalString::from_bytes(v))
        }
        let implicit = BuildImplicitVars::{ ins: in_paths, outs: out_paths }
        // 5. Evaluate command
        let cmdline = match rule_vars.get("command") {
          Some(cmd_template) =>
            Some(cmd_template.evaluate([implicit, build_vars, rule_vars]))
          None => None
        }
        // 6. Create and add build
        let build = Build::{ cmdline, ins: in_ids, outs: out_ids }
        loader.graph.add_build(build)
      }
      Default(defaults) =>
        for d in defaults {
          let file_id = loader.graph.get_file_id(bytes_to_string(d))
          loader.default.push(file_id)
        }
    }
  }
  { graph: loader.graph, default: loader.default }
}
