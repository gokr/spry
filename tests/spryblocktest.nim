import unittest, spryvm, spryunittest

# The VM module to test
import spryblock

suite "spry block":
  setup:
    let vm = newInterpreter()
    vm.addBlock()
  test "newBlock":
    check run("a = newBlock a add: 1 a add: 2") == "[1 2]"
    check run("a = newBlock: 2 a at: 0 put: 1 a at: 1 put: 2") == "[1 2]"
  test "fill":
    check run("newBlock: 2") == "[nil nil]"
    check run("a = newBlock: 2 a at: 0 put: 9") == "[9 nil]"
  test "reverse":
    check run("[1 2 3] reverse") == "[3 2 1]"
