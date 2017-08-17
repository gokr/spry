import unittest, spryvm, spryunittest

# The VM module to test
import sprycore, spryblock

suite "spry block":
  setup:
    let vm = newInterpreter()
    vm.addCore()
    vm.addBlock()

  test "newBlock":
    check run("a = newBlock a add: 1 a add: 2") == "[1 2]"
    check run("a = newBlock: 2 a at: 0 put: 1 a at: 1 put: 2") == "[1 2]"

  test "access":
    check run("[3 4] first") == "3"
    check run("[3 4] second") == "4"
    check run("[3 4] last") == "4"

  test "fill":
    check run("newBlock: 2") == "[nil nil]"
    check run("a = newBlock: 2 a at: 0 put: 9") == "[9 nil]"

  test "reverse":
    check run("[1 2 3] reverse") == "[3 2 1]"

  test "streaming":
    check run("x = [3 4] x read") == "3"
    check run("x = [3 4] x pos: 1 x read") == "4"
    check run("x = [3 4] x pos: 1 x reset x read") == "3"
    check run("x = [3 4] x next") == "3"
    check run("x = [3 4] x next x next") == "4"
    check run("x = [3 4] x next x end?") == "false"
    check run("x = [3 4] x next x next x end?") == "true"
    check run("x = [3 4] x next x next x next") == "undef"
    check run("x = [3 4] x next x next x prev") == "4"
    check run("x = [3 4] x next x next x prev x prev") == "3"
    check run("x = [3 4] x pos") == "0"
    check run("x = [3 4] x next x pos") == "1"
    check run("x = [3 4] x write: 5") == "[5 4]"

  test "meta":
    check run("x = func [3 + 4] $x write: 5 x") == "9"

  test "detect":
    check run("""
    [1 2 3 4] detect: [:each > 2]
    """) == "3"

  test "map":
    check run("""
    [1 2 3 4] map: [:each + 1]
    """) == "[2 3 4 5]"

  test "select":
    check run("""
    [1 2 3 4] select: [:each > 2]
    """) == "[3 4]"

  test "spryselect":
    check run("""
    [1 2 3 4] spryselect: [:each > 2]
    """) == "[3 4]"

  test "map":
    check run("""
    map: = method [:lambda
    result = []
    self reset
    [self end?] whileFalse: [
      result add: (do lambda (self next)) ]
    ^ result ]
    [1 2 3 4] map: [:x * 2]
    """) == "[2 4 6 8]"

