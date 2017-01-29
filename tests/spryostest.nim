import unittest, spryvm, spryunittest

# The VM module to test
import sprycore, spryos

suite "spry os":
  setup:
    let vm = newInterpreter()
    vm.addCore()
    vm.addOS()

  test "basics":
    check run("shell \"ls data.spry\"") == "\"data.spry\\x0A\""
