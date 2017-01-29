import unittest, spryvm, spryunittest, sprycore, spryreflect

suite "spry reflect":
  setup:
    let vm = newInterpreter()
    vm.addCore()
    vm.addReflect()
  test "type":
    check:
      run("x type") == "'undefined"
      run("x = 0 x type") == "'int"
      run("x = 0.5 x type") == "'float"
      run("x = \"a\" x type") == "'string"
      run("x = [] x type") == "'block"
      run("x = nil x type") == "'novalue"
      run("x = true x type") == "'boolean"
  test "source":
    check:
      run("'mm = func [1 + :n] $mm source: \"1 + :n\" $mm source") == "\"1 + :n\""
      run("'mm = method [self + 1] $mm source: \"self + 1\" $mm source") == "\"self + 1\""
