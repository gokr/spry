import ni, extend

# Some helpers for tests below
proc show(code: string): string =
  result = $newParser().parse(code)
  echo("RESULT:" & result)

proc run(code: string): string =
  result = $newInterpreter().eval(code)
  echo("RESULT:" & result)


# A bunch of tests for Parser
when true:
  # Four kinds of words, as normal Rebol/Red has
  assert(show("one") == "[one]")
  assert(show(":one") == "[:one]")
  assert(show("one:") == "[one:]")
  assert(show("'one") == "['one]")
  assert(show("""
red
green
blue""") == "[red green blue]")

  # The most trivial datatype, integer!
  assert(show("11") == "[11]")
  assert(newParser().parse("11").nodes[0].kind == niValue)
  assert(show("+11") == "[11]")
  assert(show("-11") == "[-11]")

  # String
  assert(show("\"garf\"") == "[\"garf\"]")
  
  # Just nesting and mixing
  assert(show("one :two") == "[one :two]")
  assert(show("[]") == "[[]]")
  assert(show("()") == "[()]")
  assert(show("{}") == "[{}]")
  assert(show("one two [three]") == "[one two [three]]")
  assert(show("one (two) {four [three] five}") == "[one (two) {four [three] five}]")
  assert(show(":one [two: ['three]]") == "[:one [two: ['three]]]")    
  assert(show(":one [123 -4['three]+5]") == "[:one [123 -4 ['three] 5]]")
  
  assert(show(">") == "[>]")
  assert(show("10.30") == "[10.3]")
  assert(newParser().parse("10.30").nodes[0].kind == niValue)
    
  # A real code Rebol code sample
  assert(show("""loop 10 [print "hello"]

if time > 10:30 [send jim news]

sites: [
    http://www.rebol.com [save %reb.html data]
    http://www.cnn.com   [print data]
    ftp://www.amiga.com  [send cs@org.foo data]
]

foreach [site action] sites [
    data: read site
    do action
]""") == """[loop 10 [print "hello"] if time > 10:30 [send jim news] sites: [http://www.rebol.com [save %reb.html data] http://www.cnn.com [print data] ftp://www.amiga.com [send cs@org.foo data]] foreach [site action] sites [data: read site do action]]""")

# Tests for Interpreter
when true:
  # Parse properly, show renders the Node tree
  assert(show("3 + 4") == "[3 + 4]")
  # And run
  assert(run("3 + 4") == "7")

  # A block is just a block, no evaluation
  assert(show("[3 + 4]") == "[[3 + 4]]")
  assert(run("[3 + 4]") == "[3 %+:proc(2)% 4]")

  # But we can use do to evaluate it
  assert(show("do [3 + 4]") == "[do [3 + 4]]")
  assert(run("do [4 + 3]") == "7")

  # And we can nest also, since a block has its own Activation
  # Note that only last result of block is used so "1 + 7" is dead code
  assert(run("5 + do [3 + do [1 + 7 1 + 9]]") == "18")

  # Strings
  assert(run("\"ab[c\"") == "\"ab[c\"")

  # Set and get globals
  assert(run("x: 4 5 + x") == "9")
  assert(run("x: 4 do [y: (x + 3)] y + x") == "11")
  assert(run("x: 1 do [x: (x + 1)] x") == "2")

  # Use parse word
  assert(run("parse \"3 + 4\"") == "[3 + 4]")
  assert(run("do parse \"3 + 4\"") == "7")

  # More math and boolean
  assert(run("5 - 3 + 1") == "3")
  assert(run("3 * 4") == "12")
  assert(run("3 + 4 * 2") == "14") # Yeah
  assert(run("3 < 4") == "true")
  assert(run("3 > 4") == "false")

  # if and ifelse and echo
  assert(run("x: true if x [true]") == "true")
  assert(run("x: false if x [true]") == "nil")
  assert(run("if (3 < 4) [\"yay\"]") == "\"yay\"")
  assert(run("if (3 > 4) [\"yay\"]") == "nil")
  assert(run("ifelse (3 > 4) [\"yay\"] ['ok]") == "'ok")
  
  # Factorial using a global n and f. Note that this recursive block causes
  # $ to fail in debugging since string representation never ends :)
  assert(run("""
  n: 12
  f: 1
  factorial: [ifelse (n > 1) [f: (f * n) n: (n - 1) do factorial] [f]]
  loop 1000 [n: 12 f: 1 do factorial]
  do factorial
  """) == "479001600")

when true:
  # Demonstrate extension from extend.nim
  assert(newParser().parse("'''abc'''").nodes[0].kind == niValue)
  assert(show("'''abc'''") == "[\"abc\"]")
  assert(run("reduce [1 + 2 3 + 4]") == "[3 7]")
  
  
