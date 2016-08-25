import unittest, spryvm, spryunittest, sprymemfile

suite "spry memfile":
  setup:
    let vm = newInterpreter()
    vm.addMemfile()
  test "readlines":
    check:
      run("(readLines \"data.spry\") size") == "14"

