import unittest, spryvm, spryunittest

# The VM module to test
import sprycore, spryio

suite "spry io":
  setup:
    let vm = newInterpreter()
    vm.addCore()
    vm.addIO()

  test "files":
    check run("((parse readFile \"data.spry\") at: 0) at: 0") == "121412"
