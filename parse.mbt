///|
/// A rule definition in a ninja file
priv struct RuleStmt {
  name : Bytes
  vars : Map[Bytes, Bytes]
} derive(Debug)

///|
/// A build statement in a ninja file
priv struct BuildStmt {
  rule : Bytes
  outs : Bytes
  ins : Bytes
  vars : Map[Bytes, Bytes]
} derive(Debug)

///|
/// Parsed statements from a ninja file
priv enum Statement {
  RuleStmt(RuleStmt)
  BuildStmt(BuildStmt)
  Default(Array[Bytes])
} derive(Debug)

///|
/// Parser for .ninja files
priv struct Parser {
  mut source : BytesView
}

///|
async fn parse_ninja_file(
  filename? : String = "build.ninja",
) -> Array[Statement] {
  let content = @fs.read_file(filename)
  parse_bytes(content.binary())
}

///|
fn parse_bytes(input : Bytes) -> Array[Statement] raise {
  let parser = Parser::new(input)
  parser.parse()
}

///|
/// Create a new parser
fn Parser::new(text : Bytes) -> Parser {
  { source: text }
}

///|
fn Parser::parse(self : Parser) -> Array[Statement] raise {
  let res = []
  for {
    lexmatch self.source {
      ("#.*?\n", rest) => {
        // skip comment until end of line
        self.source = rest
        continue
      }
      ("\n", rest) => {
        // skip empty line
        self.source = rest
        continue
      }
      ("rule", _) => {
        res.push(RuleStmt(self.parse_rule()))
        continue
      }
      ("build", _) => {
        res.push(BuildStmt(self.parse_build()))
        continue
      }
      ("default", rest) => {
        let defaults = []
        let rest = for rest = rest {
          lexmatch rest {
            ("[ \t]+" ("[^ \t\n]+" as def) (".*" as r)) => {
              defaults.push(def.to_bytes())
              continue r
            }
            ("\n", r) => {
              res.push(Default(defaults))
              break r
            }
            _ => fail("invalid default syntax")
          }
        }
        self.source = rest
      }
      "" => break
      _ => fail("unknown statement: \{self.source}")
    }
  }
  res
}

///|
fn Parser::parse_rule(self : Parser) -> RuleStmt raise {
  lexmatch self.source {
    (
      "rule"
      "[ \t]+"
      ("[a-zA-Z0-9_]+" as name)
      "[ \t]*\n"
      ("(  [^\n]*\n?)*" as body)
      (".*" as rest)
    ) => {
      self.source = rest
      let vars = parse_bindings(body)
      { name: name.to_bytes(), vars }
    }
    _ => fail("invalid rule syntax")
  }
}

///|
fn Parser::parse_build(self : Parser) -> BuildStmt raise {
  // Match: build outputs: rulename inputs
  lexmatch self.source {
    (
      "build"
      "[ \t]+"
      ("[^:\n]+" as outputs_str)
      ":"
      "[ \t]*"
      ("[a-zA-Z0-9_]+" as rule_name)
      ("[^\n]*" as inputs_str)
      "\n"
      ("(  [^\n]*\n?)*" as body)
      (".*" as rest)
    ) => {
      self.source = rest
      let vars = parse_bindings(body)
      {
        rule: rule_name.to_bytes(),
        outs: outputs_str.to_bytes(),
        ins: inputs_str.to_bytes(),
        vars,
      }
    }
    _ => fail("invalid build syntax")
  }
}

///|
fn parse_bindings(input : BytesView) -> Map[Bytes, Bytes] raise {
  let vars = {}
  let mut rest = input
  for {
    lexmatch rest {
      "" => break
      (
        "  "
        ("[a-zA-Z0-9_]+" as key)
        "[ \t]*=[ \t]*"
        ("[^\n]+" as value)
        "[\n]?"
        (".*" as r)
      ) => {
        vars.set(key.to_bytes(), value.to_bytes())
        rest = r
        continue
      }
      _ => fail("invalid binding syntax")
    }
  }
  vars
}
