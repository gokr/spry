import ni

# Some helpers for tests below
proc show(code: string): string =
  result = $newParser().parse(code)
  echo(result)

proc run(code: string): string =
  result = $newInterpreter().eval(code)
  echo(result)


# A bunch of unit tests
when isMainModule:
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
  assert(show("10.30") == "[10.30]")
  assert(newParser().parse("10.30").nodes[0].kind == niWord)
    
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

  # Parse properly, show renders the Node tree
  assert(show("add 3 4") == "[add 3 4]")
  # And run
  assert(run("add 3 4") == "7")

  # A block is just a block, no evaluation
  assert(show("[add 3 4]") == "[[add 3 4]]")
  assert(run("[add 3 4]") == "[add 3 4]")

  # But we can use do to evaluate it
  assert(show("do [add 3 4]") == "[do [add 3 4]]")
  assert(run("do [add 3 4]") == "7")

  # And we can nest also, since a block has its own Activation
  # Note that only last result of block is used so "add 1 7" is dead code
  assert(run("add 5 do [add 3 do [add 1 7 add 1 9]]") == "18")

  # Strings
  assert(run("\"ab[c\"") == "\"ab[c\"")

  # Set and get globals
  assert(run("x: 4 add 5 x") == "9")
  assert(run("x: 4 do [y: add x 3] add y x") == "11")

  # Use parse word
  assert(run("parse \"add 3 4\"") == "[add 3 4]")
  assert(run("do parse \"add 3 4\"") == "7")

  # More math and boolean
  assert(run("add sub 5 3 1") == "3")
  assert(run("mul 3 4") == "12")
  assert(run("lt 3 4") == "true")
  assert(run("gt 3 4") == "false")

  # if and ifelse and echo
  assert(run("if lt 3 4 [\"yay\"]") == "\"yay\"")
  assert(run("if gt 3 4 [\"yay\"]") == "false")
  assert(run("ifelse gt 3 4 [\"yay\"] ['ok]") == "'ok")
  
  # Factorial using a global n
  assert(run("""
  n: 12
  f: 1
  factorial: [ifelse gt n 1 [f: mul f n n: sub n 1 do factorial] [f]]
  do factorial
  """) == "479001600")
