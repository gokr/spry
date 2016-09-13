import unittest, spryvm, spryunittest

# The VM module to test
import sprycore, spryextend

suite "spry extend":
  setup:
    let vm = newInterpreter()
    vm.addCore()
    vm.addExtend()

  test "multiline string literal":
    check show("'''abc'''") == "\"abc\""
  test "reduce":
    check run("reduce [1 + 2 3 + 4]") == "[3 7]"
