import ni, niparser, extend

# Some helpers for tests below
proc show(code: string): string =
  result = $newParser().parse(code)
  echo("RESULT:" & $result)
  
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

  # But we can use do to evaluate it
  assert(show("do [3 + 4]") == "[do [3 + 4]]")
  assert(run("do [4 + 3]") == "7")
  
  # Or we can resolve which binds words
  assert(run("resolve [3 + 4]") == "[3 + 4]") # "[3 %+:proc-infix(2)% 4]")
  # But we need to use func to make a closure from it
  assert(run("func [] [3 + 4]") == "[[] [3 + 4]]") #"func(0)[3 %+:proc-infix(2)% 4]")
  # Which will evaluate
  assert(run("f: func [] [3 + 4] f") == "7")
  
  # Precedence and basic math
  assert(run("3 * 4") == "12")
  assert(run("3 + 1.5") == "4.5")
  assert(run("5 - 3 + 1") == "3") # Left to right
  assert(run("3 + 4 * 2") == "14") # Yeah
  assert(run("3 + (4 * 2)") == "11") # Thank god
  assert(run("3 / 2") == "1.5") # Goes to float
  assert(run("3 / 2 * 1.2") == "1.8") # 
  assert(run("3 + 3 * 1.5") == "9.0") # Goes to float
  
  # And we can nest also, since a block has its own Activation
  # Note that only last result of block is used so "1 + 7" is dead code
  assert(run("5 + do [3 + do [1 + 7 1 + 9]]") == "18")

  # Strings
  assert(run("\"ab[c\"") == "\"ab[c\"")
  assert(run("\"ab\" & \"cd\"") == "\"abcd\"")

  # Set and get globals
  assert(run("x: 4 5 + x") == "9")
  assert(run("x: 4 k: do [y: x + 3 y] k + x") == "11")
  assert(run("x: 1 do [x: (x + 1)] x") == "2")

  # Use parse word
  assert(run("parse \"3 + 4\"") == "[3 + 4]")
  assert(run("do parse \"3 + 4\"") == "7")

  # Boolean
  assert(run("true") == "true")
  assert(run("not true") == "false")
  assert(run("false") == "false")
  assert(run("not false") == "true")
  assert(run("3 < 4") == "true")
  assert(run("3 > 4") == "false")
  assert(run("not 3 > 4") == "true")
  assert(run("false or false") == "false")
  assert(run("true or false") == "true")
  assert(run("false or true") == "true")
  assert(run("3 > 4 or 3 < 4") == "true")
  assert(run("3 > 4 and 3 < 4") == "false")
  assert(run("7 > 4 and 3 < 4") == "true")

  # Block indexing and positioning
  assert(run("[3 4] len") == "2")
  assert(run("[] len") == "0")
  assert(run("[3 4] first") == "3")
  assert(run("[3 4] second") == "4")
  assert(run("[3 4] last") == "4")
  assert(run("[3 4] at 0") == "3")
  assert(run("[3 4] at 1") == "4")
  assert(run("[3 4] at 1") == "4")
  assert(run("[3 4] put 0 5") == "[5 4]")
  assert(run("x: [3 4] x put 1 5 x") == "[3 5]")
  assert(run("x: [3 4] x read") == "3")
  assert(run("x: [3 4] x setpos 1 x read") == "4")
  assert(run("x: [3 4] x setpos 1 x reset x read") == "3")
  assert(run("x: [3 4] x next") == "3")
  assert(run("x: [3 4] x next x next") == "4")
  assert(run("x: [3 4] x pos") == "0")
  assert(run("x: [3 4] x next x pos") == "1")
  assert(run("x: [3 4] x write 5") == "[5 4]")
  
  # if and ifelse and echo
  assert(run("x: true if x [true]") == "true")
  assert(run("x: false if x [true]") == "nil")
  assert(run("if 3 < 4 [\"yay\"]") == "\"yay\"")
  assert(run("if 3 > 4 [\"yay\"]") == "nil")
  assert(run("ifelse 3 > 4 [\"yay\"] ['ok]") == "'ok")
  
  # func
  assert(run("z: func [] [3 + 4] z") == "7")
  assert(run("x: func [] [3 + 4] :x") == "[[] [3 + 4]]")
  assert(run("x: func [] [3 + 4] 'x") == "'x")
  assert(run("x: func [] [3 + 4] :x second write 5 x") == "9")
  
  # func args
  assert(run("x: func [a] [a] x 5") == "5")
  assert(run("x: func [a b] [b] x 5 4") == "4")
  assert(run("x: func [a b] [a + b] x 5 4") == "9")
  assert(run("z: 15 x: func [a b] [a + b + z] x 1 2") == "18")

  # func infix works too, and with 3 or more arguments too...
  assert(run("xx: func-infix [a b] [a + b + b] 5 xx 4 xx 2") == "17") # 5+4+4 + 2+2
  assert(run("pick2add: func-infix [block b c] [ block at b + (block at c)] [1 2 3] pick2add 0 2") == "4") # 1+3
  
  # TODO: func closures, this test currently fails! The second call to c overwrites the closed a value.
  # I think this is because our bindings are made destructively into the bodies without cloning them.
  #assert(run("c: func [a] [func [b] [a + b]] d: c 1 e: c 2 reduce [d 1 d 2 e 1 e 2]") == "[2 3 3 4]")
  
  # Factorial using a global n and f. Note that this recursive block causes
  # $ to fail in debugging since string representation never ends :)
  assert(run("""
  n: 12
  f: 1
  factorial: func [] [ifelse n > 1 [
    f: f * n
    n: n - 1
    factorial]
  [
    f]
  ]
  loop 1000 [n: 12 f: 1 factorial]
  factorial
  """) == "479001600")

  # Ok, but now we can do arguments so...
  assert(run("""
  factorial: func [n] [ifelse n > 0 [n * factorial (n - 1)] [1]]
  factorial 12
  """) == "479001600")
when true:
  # Demonstrate extension from extend.nim
  assert(show("'''abc'''") == "[\"abc\"]")
  assert(run("reduce [1 + 2 3 + 4]") == "[3 7]")  
  
