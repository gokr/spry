import unittest, spryvm, spryunittest

# The VM module to test
import sprymath

suite "spry math":
  setup:
    let vm = newInterpreter()
    #vm.addCore() # ...if you need +, - etc!
    vm.addMath()

  test "basics":
    check run("12 negated") == "-12"
    check run("-12.5 negated") == "12.5"
    check run("10 fac") == "3628800"
    check run("4.0 cos") == "-0.6536436208636119"
    check run("128 powerOfTwo?") == "true"
    check run("129 powerOfTwo?") == "false"
    check run("64 nextPowerOfTwo") == "64"
    check run("61 nextPowerOfTwo") == "64"
    check run("25 sqrt") == "5.0"
    check run("25.0 sqrt") == "5.0"

