///|
test "parse1" {
  let input : String =
    #|# Example 1: Simple Hello World
    #|# This demonstrates basic ninja syntax with a simple shell command
    #|
    #|rule greet
    #|  command = echo "Hello from $name!" > $out
    #|  description = Greeting $name
    #|
    #|build hello.txt: greet
    #|  name = Ninja Build System
    #|
    #|build world.txt: greet
    #|  name = n2
    #|
    #|rule combine
    #|  command = cat $in > $out
    #|  description = Combining greetings
    #|
    #|build combined.txt: combine hello.txt world.txt
    #|
    #|default combined.txt
    #|
  let parsed = parse_bytes(@utf8.encode(input))
  debug_inspect(
    parsed,
    content=(
      #|[
      #|  RuleStmt(
      #|    {
      #|      name: <Bytes: ...>,
      #|      vars: { ...: ..., ...: ... },
      #|    },
      #|  ),
      #|  BuildStmt(
      #|    {
      #|      rule: <Bytes: ...>,
      #|      outs: <Bytes: ...>,
      #|      ins: <Bytes: []>,
      #|      vars: { ...: ... },
      #|    },
      #|  ),
      #|  BuildStmt(
      #|    {
      #|      rule: <Bytes: ...>,
      #|      outs: <Bytes: ...>,
      #|      ins: <Bytes: []>,
      #|      vars: { ...: ... },
      #|    },
      #|  ),
      #|  RuleStmt(
      #|    {
      #|      name: <Bytes: ...>,
      #|      vars: { ...: ..., ...: ... },
      #|    },
      #|  ),
      #|  BuildStmt(
      #|    {
      #|      rule: <Bytes: ...>,
      #|      outs: <Bytes: ...>,
      #|      ins: <Bytes: ...>,
      #|      vars: {},
      #|    },
      #|  ),
      #|  Default([<Bytes: ...>]),
      #|]
    ),
  )
}

///|
test "eval_string_from_bytes" {
  // Test simple literal
  let es1 = EvalString::from_bytes(b"hello world")
  inspect(es1.evaluate([]), content="hello world")

  // Test simple variable reference
  let es2 = EvalString::from_bytes(b"$foo")
  let env : Map[String, EvalString] = {}
  env.set("foo", EvalString::from_bytes(b"bar"))
  inspect(es2.evaluate([env]), content="bar")

  // Test mixed literal and variable
  let es3 = EvalString::from_bytes(b"gcc -c $in -o $out")
  let implicit = BuildImplicitVars::{ ins: ["foo.c"], outs: ["foo.o"] }
  inspect(es3.evaluate([implicit]), content="gcc -c foo.c -o foo.o")

  // Test escaped $$
  let es4 = EvalString::from_bytes(b"echo $$HOME")
  inspect(es4.evaluate([]), content="echo $HOME")

  // Test ${braced} variable
  let es5 = EvalString::from_bytes(b"${foo}bar")
  inspect(es5.evaluate([env]), content="barbar")
}

///|
test "load_ninja" {
  let input : String =
    #|rule cc
    #|  command = gcc -c $in -o $out
    #|
    #|build foo.o: cc foo.c
    #|build bar.o: cc bar.c
    #|
    #|default foo.o
    #|
  let parsed = parse_bytes(@utf8.encode(input))
  let state = read(parsed)

  // Check that we have 2 builds
  inspect(state.graph.builds.length(), content="2")

  // Check that files are created
  inspect(state.graph.file_by_name.length(), content="4") // foo.o, foo.c, bar.o, bar.c

  // Check command evaluation
  let build0 = state.graph.builds.get(BuildId(0)).unwrap()
  inspect(build0.cmdline, content="Some(\"gcc -c foo.c -o foo.o\")")
  let build1 = state.graph.builds.get(BuildId(1)).unwrap()
  inspect(build1.cmdline, content="Some(\"gcc -c bar.c -o bar.o\")")

  // Check defaults
  inspect(state.default.length(), content="1")
}
