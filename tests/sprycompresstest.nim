import unittest, spryvm, spryunittest

# The VM module to test
import sprycore, sprycompress

suite "spry compress":
  setup:
    let vm = newInterpreter()
    vm.addCore()
    vm.addCompress()
  test "compress":
    check run("compress \"abc123\"") == "\"\\x06\\x00\\x00\\x00`abc123\""
  test "uncompress":
    check run("uncompress (compress \"abc123\")") == "\"abc123\""
