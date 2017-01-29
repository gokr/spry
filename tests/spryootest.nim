import unittest, spryvm, spryunittest

# The VM module to test
import sprycore, spryextend, sprylib, spryoo

suite "spry oo":
  setup:
    let vm = newInterpreter()
    vm.addCore()
    vm.addExtend() # reduce...
    vm.addLib()
    vm.addOO()

  test "tags":
    check run("o = {x = 5} o tag: 'object o tags") == "['object]"
    check run("o = object [] {x = 5} o tags") == "['object]"
    check run("o = \"foo\" getx = method [^ @x] o getx") == "undef" # Because @ works only for objects
    check run("o = {x = 5} getx = method [^ @x] o tag: 'object o getx") == "5"
    check run("o = {x = 5} getx = method [eva @x] o tag: 'object o getx") == "5"
    check run("o = {x = 5} xplus = method [@x + 1] o tag: 'object o xplus") == "6"
    check run("o = {x = 5} xplus = method [do [x = 4 @x + 1]] o tag: 'object o xplus") == "6"

    # spry polymeth (reduce should not be needed here)
  test "polymethod":
    check run("p = polymethod reduce [method [self + 1] method [self]]") == "polymethod [method [self + 1] method [self]]"
    check run("[int string] -> [self]") == "method [self]"
    check run("$([int string] -> [self]) tags") == "[int string]"
    check run("p = polymethod reduce [[int] -> [1] [string] -> [2]]") == "polymethod [method [1] method [2]]"
    check run("p = polymethod reduce [[int] -> [1] [string] -> [2]] 42 p") == "nil"
    check run("inc = polymethod reduce [[int] -> [self + 1] [string] -> [self , \"c\"]] (42 tag: 'int) inc") == "43"
    check run("inc = polymethod reduce [[int] -> [self + 1] [string] -> [self , \"c\"]] (\"ab\" tag: 'string) inc") == "\"abc\""
