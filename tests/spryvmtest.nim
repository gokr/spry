import unittest, spryvm, spryunittest

suite "spry vm":
  setup:
    let vm = newInterpreter()

  test "parse comments":
    check show("[3 + 4 # foo]") == "[3 + 4]"

  test "parse word kinds":
    check identical("one")        # Eval word
    check identical("@one")       # Eval word, self ref
    check identical("..one")      # Eval word, start resolve outside
    check identical(".one")       # Eval word, only local
    check identical("$one")       # Lookup word
    check identical("$@one")      # Lookup word, self ref
    check identical("$..one")     # Lookup word, start resolve outside
    check identical("$.one")      # Lookup word, only local
    check identical(":one")       # Arg word, pulls in from caller
    check identical(":$one")      # Arg word, pulls in without eval
    check identical("'one")       # Literal word
    check identical("'@one")      # Literal word
    check identical("'..one")     # Literal word
    check identical("'$..one")    # Literal word
    check identical("'.one")      # Literal word
    check identical("'$.one")     # Literal word
    check identical("':one")      # Literal word
    check identical("':$one")     # Literal word
    check identical("''one")      # Literal word

  test "parse integers":
    check show("11") == "11"
    check show("+11") == "11"
    check show("-11") == "-11"
    check show("1_000_000") == "1000000"

  test "parse floats":
    check show("1.0e3") == "1000.0"
    check show("10.30") == "10.3"

  # String with basic escapes using Nim's escape/unescape
  test "parse strings":
    check show("\"garf\"") == "\"garf\""
    check show("\"ga\\\"rf\"") == "\"ga\\\"rf\""

  test "parse composites":
    check show("[one :two]") == "[one :two]"
    check show("[]") == "[]"
    check show("()") == "()"
    check show("{}") == "{}"
    check show("[one two [three]]") == "[one two [three]]"
    check show("[one (two) {four [three] five}]") == "[one (two) {four [three] five}]"
    check show("[:one [:two ['three]]]") == "[:one [:two ['three]]]"
    check show("[:one [123 -4['three]+5]]") == "[:one [123 -4 ['three] 5]]"
    check show("""
[
red
green
blue
]""") == "[red green blue]"

  test "parse keywords":
    check show("[[1 2] at: 0 put: 1]") == "[[1 2] at:put: 0 1]"
    check show("[4 repeat: [echo 34]]") == "[4 repeat: [echo 34]]"
    check show("[[3 < 4] whileTrue: [5 repeat: [echo 42]]]") == "[[3 < 4] whileTrue: [5 repeat: [echo 42]]]"
    check show("[[3 4] at: [1 2 [hey]] put: [5 repeat: [echo 42]]]") == "[[3 4] at:put: [1 2 [hey]] [5 repeat: [echo 42]]]"
