import unittest, spryvm, spryunittest

# The VM module to test
import sprycore, sprystring

suite "spry string":
  setup:
    let vm = newInterpreter()
    vm.addCore()
    vm.addString()

  test "basics":
    check run("\"abc.de\" split: \".\"") == "[\"abc\" \"de\"]"
    check run("\"abc.de\" findString: \"bc\"") == "1"
    check run("\"abc.de\" findString: \"zz\"") == "-1"
    check run("\"aabcaaaaaabc\" findString: \"bc\" startingAt: 5") == "10"
    check run("a = \"a bob bob world\" b = (a clone) a replace: \"bob\" with: \"zap\" (b, a)") == "\"a bob bob worlda zap zap world\""
