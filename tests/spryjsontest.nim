import unittest, spryvm, spryunittest

# The VM module to test
import sprycore, spryjson

suite "spry JSON":
  setup:
    let vm = newInterpreter()
    vm.addCore()
    vm.addJSON()

  test "parse":
    check run("""
        parseJSON "{\"age\": 35, \"pi\": 3.1415}"
        """) == "{\"age\":35,\"pi\":3.1415}"

  test "tospry":
    check run("""
      (parseJSON "{\"age\": 35, \"pi\": 3.1415}") toSpry
      """) == "{\"age\" = 35 \"pi\" = 3.1415}"

  test "toJSON":
    check run("""
      (parseJSON "{\"age\": 35, \"pi\": 3.1415}") toSpry toJSON
     """) == "{\"age\":35,\"pi\":3.1415}"
