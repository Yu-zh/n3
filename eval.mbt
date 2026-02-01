///|
/// One token within an EvalString, either literal text or a variable reference
priv enum EvalPart {
  Literal(String)
  VarRef(String)
}

///|
/// A parsed but unexpanded variable-reference string, e.g. "cc $in -o $out"
priv struct EvalString {
  parts : Array[EvalPart]
}

///|
fn is_var_char(c : Byte) -> Bool {
  (c >= b'a' && c <= b'z') ||
  (c >= b'A' && c <= b'Z') ||
  (c >= b'0' && c <= b'9') ||
  c == b'_'
}

///|
fn bytes_slice_to_string(b : Bytes, start : Int, end : Int) -> String {
  let len = end - start
  let buf = StringBuilder::new()
  for i in 0..<len {
    buf.write_char(b[start + i].to_int().unsafe_to_char())
  }
  buf.to_string()
}

///|
fn EvalString::from_bytes(input : Bytes) -> EvalString {
  let parts : Array[EvalPart] = []
  let mut i = 0
  let mut literal_start = 0
  let len = input.length()
  while i < len {
    if input[i] == b'$' {
      // Flush literal before this
      if i > literal_start {
        parts.push(Literal(bytes_slice_to_string(input, literal_start, i)))
      }
      i += 1
      if i >= len {
        break
      }
      if input[i] == b'$' {
        // Escaped $$ -> $
        parts.push(Literal("$"))
        i += 1
        literal_start = i
      } else if input[i] == b'{' {
        // ${varname}
        i += 1
        let var_start = i
        while i < len && input[i] != b'}' {
          i += 1
        }
        parts.push(VarRef(bytes_slice_to_string(input, var_start, i)))
        i += 1 // skip '}'
        literal_start = i
      } else {
        // $varname (alphanumeric + underscore)
        let var_start = i
        while i < len && is_var_char(input[i]) {
          i += 1
        }
        parts.push(VarRef(bytes_slice_to_string(input, var_start, i)))
        literal_start = i
      }
    } else {
      i += 1
    }
  }
  // Flush remaining literal
  if literal_start < len {
    parts.push(Literal(bytes_slice_to_string(input, literal_start, len)))
  }
  { parts, }
}

///|
/// Environment trait for looking up variables
priv trait Env {
  get_var(Self, String) -> String?
}

///|
/// Evaluate the EvalString by looking up variables in the provided environments
fn EvalString::evaluate(self : EvalString, envs : Array[&Env]) -> String {
  let mut result = ""
  for part in self.parts {
    match part {
      Literal(s) => result = result + s
      VarRef(v) =>
        for i = 0; i < envs.length(); i = i + 1 {
          match envs[i].get_var(v) {
            Some(val) => {
              result = result + val
              break
            }
            None => ()
          }
        }
    }
  }
  result
}

///|
/// Built-in variables for $in and $out in build statements
priv struct BuildImplicitVars {
  ins : Array[String]
  outs : Array[String]
}

///|
impl Env for BuildImplicitVars with get_var(self, name) {
  match name {
    "in" => Some(self.ins.join(" "))
    "out" => Some(self.outs.join(" "))
    _ => None
  }
}

///|
/// Env implementation for Map[String, EvalString]
impl Env for Map[String, EvalString] with get_var(self, name) {
  match self.get(name) {
    Some(es) => Some(es.evaluate([]))
    None => None
  }
}
