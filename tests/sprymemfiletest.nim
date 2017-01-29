import unittest, spryvm, spryunittest, sprycore, sprymemfile

suite "spry memfile":
  setup:
    let vm = newInterpreter()
    vm.addCore()
    vm.addMemfile()
  test "readlines":
    check:
      run("(readLines \"data.spry\") size") == "14"

