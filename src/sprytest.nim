import spryvm

import spryextend, sprymath, spryio, sprydebug, sprycompress, spryos, sprythread, sprypython, spryoo,
  sprystring, sprymodules

proc newVM(): Interpreter =
  var spry = newInterpreter()
  spry.addExtend()
  spry.addMath()
  spry.addOS()
  spry.addIO()
  spry.addThread()
  spry.addPython()
  spry.addDebug()
  spry.addCompress()
  spry.addOO()
  spry.addString()
  spry.addModules()
  return spry

# Some helpers for tests below
proc show(code: string): string =
  result = $newParser().parse(code)
  echo("RESULT:" & $result)
  echo("---------------------")
proc identical(code: string) =
  var result = $newParser().parse(code)
  echo("RESULT:" & $result)
  echo("---------------------")
  assert(result == code)
proc run(code: string): string =
  result = $newVM().evalRoot("[" & code & "]")
  echo("RESULT:" & result)
  echo("---------------------")
proc stringRun(code: string): string =
  # Expects a StringVal to compare with
  result = StringVal(newVM().evalRoot("[" & code & "]")).value
  echo("RESULT:" & result)
  echo("---------------------")

# A bunch of tests for Parser
when true:
  # Comments
  assert(show("[3 + 4 # foo]") == "[3 + 4]")  # Comment
  # The different kinds of words
  identical("one")        # Eval word
  identical("@one")       # Eval word, self ref
  identical("..one")      # Eval word, start resolve in parent
  identical("$one")       # Lookup word
  identical("$@one")      # Lookup word, self ref
  identical("$..one")     # Lookup word, start resolve in parent
  identical(":one")       # Arg word, pulls in from caller
  identical(":$one")      # Arg word, pulls in without eval
  identical("'one")       # Literal word
  identical("'@one")      # Literal word
  identical("'..one")     # Literal word
  identical("'$..one")    # Literal word
  identical("':one")      # Literal word
  identical("':$one")     # Literal word
  identical("''one")      # Literal word
  assert(show("[a at: 1 put: 2]") == "[a at:put: 1 2]")  # Keyword syntactic sugar
  assert(show("""
[
red
green
blue
]""") == "[red green blue]")

  # The most trivial datatype, integer!
  assert(show("11") == "11")
  assert(show("+11") == "11")
  assert(show("-11") == "-11")
  assert(show("1_000_000") == "1000000")

  # And floats
  assert(show("1.0e3") == "1000.0")
  assert(show("10.30") == "10.3")

  # String with basic escapes using Nim's escape/unescape
  assert(show("\"garf\"") == "\"garf\"")
  assert(show("\"ga\\\"rf\"") == "\"ga\\\"rf\"")

  # Just nesting and mixing
  assert(show("[one :two]") == "[one :two]")
  assert(show("[]") == "[]")
  assert(show("()") == "()")
  assert(show("{}") == "{}")
  assert(show("[one two [three]]") == "[one two [three]]")
  assert(show("[one (two) {four [three] five}]") == "[one (two) {four [three] five}]")
  assert(show("[:one [:two ['three]]]") == "[:one [:two ['three]]]")
  assert(show("[:one [123 -4['three]+5]]") == "[:one [123 -4 ['three] 5]]")

  # Keyword syntax sugar
  assert(show("[[1 2] at: 0 put: 1]") == "[[1 2] at:put: 0 1]")
  assert(show("[4 timesRepeat: [echo 34]]") == "[4 timesRepeat: [echo 34]]")
  assert(show("[[3 < 4] whileTrue: [5 timesRepeat: [echo 42]]]") == "[[3 < 4] whileTrue: [5 timesRepeat: [echo 42]]]")
  assert(show("[[3 4] at: [1 2 [hey]] put: [5 timesRepeat: [echo 42]]]") == "[[3 4] at:put: [1 2 [hey]] [5 timesRepeat: [echo 42]]]")

  assert(show(">") == ">")

# Tests for Interpreter
when true:
  # Parse properly, show renders the Node tree
  assert(show("[3 + 4]") == "[3 + 4]")
  # And run
  assert(run("3 + 4") == "7")

  # A block is just a block, no evaluation
  assert(show("[3 + 4]") == "[3 + 4]")

  # But we can use do to evaluate it
  assert(show("[do [3 + 4]]") == "[do [3 + 4]]")
  assert(run("do [4 + 3]") == "7")

  # But we need to use func to make a closure from it
  assert(run("func [3 + 4]") == "func [3 + 4]")

  # Which will evaluate itself when being evaluated
  assert(run("foo = func [3 + 4] foo") == "7")

  # Map
  assert(run("{}") == "{}")
  assert(run("{a = 1 b = 2}") == "{a = 1 b = 2}")
  assert(run("{a = 1 b = \"hey\"}") == "{a = 1 b = \"hey\"}")
  assert(run("{a = {d = (3 + 4) e = (5 + 6)}}") == "{a = {d = 7 e = 11}}")
  assert(run("{a = 3} at: 'a") == "3")
  assert(run("{3 = 4 6 = 1} at: 6") == "1") # int, In spry any Node can be a key!
  assert(run("{\"hey\" = 4 true = 1 6.0 = 8} at: \"hey\"") == "4") # string
  assert(run("{\"hey\" = 4 true = 1 6.0 = nil} at: 6.0") == "nil") # float
  #assert(run("{undef = 8} at: undef") == "8") # undef humm...
  #assert(run("{nil = 4} at: nil") == "4") # nil  humm...
  #assert(run("{true = false} at: true") == "false") # nil humm..
  assert(run("dict = {a = 3} dict at: 'a put: 5 dict at: 'a") == "5")

  # Assignment is a prim
  assert(run("x = 5") == "5")
  assert(run("x = 5 x") == "x") # Peculiarity, a word is not evaluated by default
  assert(run("x = 5 eval x") == "5") # But we can eval it
  assert(run("f = func [3 + 4] f") == "7") # Functions are evaluated though

  # Nil vs undef
  assert(run("eval x") == "undef")
  assert(run("x ?") == "false")
  assert(run("x = 1 x ?") == "true")
  assert(run("x = nil x ?") == "true")
  assert(run("x = 1 x ? if: [12]") == "12")
  assert(run("x = 1 x = undef x ?") == "false")
  assert(run("x = 5 x = undef eval x") == "undef")
  assert(run("x = 5 x = nil eval x") == "nil")

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
  assert(run("123 form") == "\"123\"")
  assert(run("\"abc123\" form") == "\"abc123\"")

  # Concatenation
  assert(run("\"ab\", \"cd\"") == "\"abcd\"")
  assert(run("[1] , [2 3]") == "[1 2 3]")


  # Set and get variables
  assert(run("x = 4 5 + x") == "9")
  assert(run("x = 1 x = x eval x") == "1")
  assert(run("x = 4 ^ x") == "4")
  assert(run("x = 1 x = (x + 2) eval x") == "3")
  assert(run("x = 4 k = do [y = (x + 3) eval y] k + x") == "11")
  assert(run("x = 1 do [x = (x + 1)] eval x") == "2")

  # Use parse word
  assert(run("parse \"[3 + 4]\"") == "[3 + 4]")
  assert(run("do parse \"[3 + 4]\"") == "7")

  # Boolean
  assert(run("true") == "true")
  assert(run("not true") == "false")
  assert(run("false") == "false")
  assert(run("not false") == "true")
  assert(run("3 < 4") == "true")
  assert(run("3 > 4") == "false")
  assert(run("not (3 > 4)") == "true")
  assert(run("false or false") == "false")
  assert(run("true or false") == "true")
  assert(run("false or true") == "true")
  assert(run("true or true") == "true")
  assert(run("false and false") == "false")
  assert(run("true and false") == "false")
  assert(run("false and true") == "false")
  assert(run("true and true") == "true")
  assert(run("3 > 4 or (3 < 4)") == "true")
  assert(run("3 > 4 and (3 < 4)") == "false")
  assert(run("7 > 4 and (3 < 4)") == "true")
  assert(run("7 >= 4") == "true")
  assert(run("4 >= 4") == "true")
  assert(run("3 >= 4") == "false")
  assert(run("7 <= 4") == "false")
  assert(run("4 <= 4") == "true")
  assert(run("3 <= 4") == "true")
  assert(run("3 == 4") == "false")
  assert(run("4 == 4") == "true")
  assert(run("3.0 == 4.0") == "false")
  assert(run("4 == 4.0") == "true")
  assert(run("4.0 == 4") == "true")
  assert(run("4.0 != 4") == "false")
  assert(run("4.1 != 4") == "true")
  assert(run("\"abc\" == \"abc\"") == "true")
  assert(run("\"abc\" == \"AAA\"") == "false")
  assert(run("true == true") == "true")
  assert(run("false == false") == "true")
  assert(run("false == true") == "false")
  assert(run("true == false") == "false")

# Will cause type exceptions
#  assert(run("false == 4") == "false")
#  assert(run("4 == false") == "false")
#  assert(run("\"ab\" == 4") == "false")
#  assert(run("4 == \"ab\"") == "false")


  # Block indexing and positioning
  assert(run("[3 4] size") == "2")
  assert(run("[] size") == "0")
  assert(run("[3 4] first") == "3")
  assert(run("[3 4] second") == "4")
  assert(run("[3 4] last") == "4")
  assert(run("[3 4] at: 0") == "3")
  assert(run("[3 4] at: 1") == "4")
  assert(run("[3 4] at: 0 put: 5") == "[5 4]")
  assert(run("x = [3 4] x at: 1 put: 5 eval x") == "[3 5]")
  assert(run("x = [3 4] x read") == "3")
  assert(run("x = [3 4] x pos: 1 x read") == "4")
  assert(run("x = [3 4] x pos: 1 x reset x read") == "3")
  assert(run("x = [3 4] x next") == "3")
  assert(run("x = [3 4] x next x next") == "4")
  assert(run("x = [3 4] x next x end?") == "false")
  assert(run("x = [3 4] x next x next x end?") == "true")
  assert(run("x = [3 4] x next x next x next") == "undef")
  assert(run("x = [3 4] x next x next x prev") == "4")
  assert(run("x = [3 4] x next x next x prev x prev") == "3")
  assert(run("x = [3 4] x pos") == "0")
  assert(run("x = [3 4] x next x pos") == "1")
  assert(run("x = [3 4] x write: 5") == "[5 4]")
  assert(run("x = [3 4] x add: 5 eval x") == "[3 4 5]")
  assert(run("x = [3 4] x removeLast eval x") == "[3]")
  assert(run("[3 4], [5 6]") == "[3 4 5 6]")
  assert(run("[3 4] contains: 3") == "true")
  assert(run("[3 4] contains: 8") == "false")
  assert(run("{x = 1 y = 2} contains: 'x") == "true")
  assert(run("{x = 1 y = 2} contains: 'z") == "false")
  assert(run("{\"x\" = 1 \"y\" = 2} contains: \"x\"") == "true")
  assert(run("{\"x\" = 1 \"y\" = 2} contains: \"z\"") == "false")
  assert(run("[false bum 3.14 4] contains: 'bum") == "true")
  assert(run("[1 2 true 4] contains: 'false") == "false") # Note that block contains words, not values
  assert(run("[1 2 true 4] contains: 'true") == "true")
  assert(run("x = false b = [] b add: x b contains: x") == "true")

  # copyFrom:to:
  assert(run("[1 2 3] copyFrom: 1 to: 2") == "[2 3]")
  assert(run("[1 2 3] copyFrom: 0 to: 1") == "[1 2]")
  assert(run("\"abcd\" copyFrom: 1 to: 2") == "\"bc\"")

  # Data as code
  assert(run("code = [1 + 2 + 3] code at: 2 put: 10 do code") == "14")

  # if:, if:else:, ifNot:, ifNot:else:
  assert(run("x = true x if: [true]") == "true")
  assert(run("x = true x if: [12]") == "12")
  assert(run("false if: [12]") == "nil")
  assert(run("x = false x if: [true]") == "nil")
  assert(run("(3 < 4) if: [\"yay\"]") == "\"yay\"")
  assert(run("(3 > 4) if: [\"yay\"]") == "nil")
  assert(run("(3 > 4) if: [\"yay\"] else: ['ok]") == "'ok")
  assert(run("(3 > 4) if: [true] else: [false]") == "false")
  assert(run("(4 > 3) if: [true] else: [false]") == "true")
  assert(run("(3 < 4) if: [5]") == "5")
  assert(run("3 < 4 if: [5]") == "5")
  assert(run("3 < 4 ifNot: [5]") == "nil")
  assert(run("3 < 4 if: [1] else: [2]") == "1")
  assert(run("3 < 4 ifNot: [1] else: [2]") == "2")
  assert(run("5 < 4 ifNot: [1] else: [2]") == "1")
  assert(run("5 < 4 if: [1] else: [2]") == "2")

  # loops, eva will
  assert(run("x = 0 5 timesRepeat: [x = (x + 1)] eva x") == "5")
  assert(run("x = 0 0 timesRepeat: [x = (x + 1)] eva x") == "0")
  assert(run("x = 0 5 timesRepeat: [x = (x + 1)] eva x") == "5")
  assert(run("x = 0 [x > 5] whileFalse: [x = (x + 1)] eva x") == "6")
  assert(run("x = 10 [x > 5] whileTrue: [x = (x - 1)] eva x") == "5")

  # func
  assert(run("z = func [3 + 4] z") == "7")
  assert(run("x = func [3 + 4] eva $x") == "func [3 + 4]")
  assert(run("x = func [3 + 4] 'x") == "'x")
  assert(run("x = func [3 + 4] $x write: 5 x") == "9")
  assert(run("x = func [3 + 4 ^ 1 8 + 9] x") == "1")
  # Its a non local return so it returns all the way, thus it works deep down
  assert(run("x = func [3 + 4 do [ 2 + 3 ^ 1 1 + 1] 8 + 9] x") == "1")

  # Testing $ word that prevents evaluation, like quote in Lisp
  assert(run("x = $(3 + 4) $x at: 2") == "4")

  # Testing literal word evaluation into the real word
  #assert(run("eva 'a") == "a")
  #assert(run("eva ':$a") == ":$a")

  # func args
  assert(run("do [:a] 5") == "5")
  assert(run("x = func [:a a + 1] x 5") == "6")
  assert(run("x = func [:a + 1] x 5") == "6") # Slicker than the above!
  assert(run("x = func [:a :b eval b] x 5 4") == "4")
  assert(run("x = func [:a :b a + b] x 5 4") == "9")
  assert(run("x = func [:a + :b] x 5 4") == "9") # Again, slicker
  assert(run("z = 15 x = func [:a :b a + b + z] x 1 2") == "18")
  assert(run("z = 15 x = func [:a + :b + z] x 1 2") == "18") # Slick indeed
  assert(run("do [:b + 3] 4") == "7") # Muhahaha!
  assert(run("do [:b + :c - 1] 4 3") == "6") # Muhahaha!
  assert(run("d = 5 do [:x] d") == "5")
  assert(run("d = 5 do [:$x] d") == "d")
  # x will be a Word, need val and key prims to access it!
  #assert(run("a = \"ab\" do [:'x & \"c\"] a") == "\"ac\"") # x becomes "a"
  assert(run("a = \"ab\" do [:x , \"c\"] a") == "\"abc\"") # x becomes "ab"

  # @ and ..
  assert(run("d = 5 do [eval $d]") == "5")
  assert(run("d = 5 do [eval $@d]") == "undef")
  assert(run("d = 5 do [eval $..d]") == "5")
  assert(run("d = 5 do [(locals at: 'd put: 3) $..d + d]") == "8")
  assert(run("d = 5 do [eval d]") == "5")
  assert(run("d = 5 do [eval @d]") == "undef")
  assert(run("d = 5 do [eval ..d]") == "5")
  assert(run("d = 5 do [(locals at: 'd put: 3) ..d + d]") == "8")

  # Not an object
  assert(run("o = {x = 5} o tag: objectTag o tags") == "[object]")
  assert(run("o = object [] {x = 5} o tags") == "[object]")
  assert(run("o = {x = 5 getx = func [^ @x]} o::getx") == "undef") # Because @ works only for objects
  assert(run("o = {x = 5 getx = func [^ @x]} o tag: objectTag o::getx") == "5")
  assert(run("o = {x = 5 getx = func [eva @x]} o tag: objectTag o::getx") == "5")
  assert(run("o = {x = 5 getx = func [^ @x] xplus = func [@x + 1]} o tag: objectTag o::xplus") == "6")
  assert(run("o = {x = 5 getx = func [^ @x] xplus = func [do [locals at: 'x put: 4 @x + 1]]} o tag: objectTag o::xplus") == "6")

  # func infix works too, and with 3 or more arguments too...
  assert(run("xx = func [:a :b a + b + b] xx 2 (xx 5 4)") == "28") # 2 + (5+4+4) + (5+4+4)
  assert(run("xx = funci [:a :b a + b] 5 xx 2") == "7") # 5 + 7
  assert(run("xx = funci [:a + :b] 5 xx 2") == "7") # 5 + 7
  assert(run("xx = funci [:a :b a + b + b] 5 xx (4 xx 2)") == "21") # 5 + (4+2+2) + (4+2+2)
  assert(run("xx = funci [:a + :b + b] (5 xx 4) xx 2") == "17") # 5+4+4 + 2+2
  assert(run("pick2add = funci [:block :b :c block at: b + (block at: c)] [1 2 3] pick2add 0 2") == "4") # 1+3
  assert(run("pick2add = funci [:block at: :b + (block at: :c)] [1 2 3] pick2add 0 2") == "4") # 1+3

  # Variadic and dynamic args
  # Does not work since there is a semantic glitch - who is the argParent?
  #assert(run("sum = 0 sum-until-zero = func [[:a > 0] whileTrue: [sum = sum + a]] (sum-until-zero 1 2 3 0 4 4)") == "6")
  # This func does not pull second arg if first is < 0.
  assert(run("add = func [ :a < 0 if: [^ nil] ^ (a + :b) ] add -4 3") == "3")
  assert(run("add = func [ :a < 0 if: [^ nil] ^ (a + :b) ] add 1 3") == "4")

  # Macros, they need to be able to return multipe nodes...
  assert(run("z = 5 foo = func [:$a ^ func [a + 10]] fupp = foo z z = 3 fupp") == "13")

  # func closures. Creates two different funcs closing over two values of a
  assert(run("c = func [:a func [a + :b]] d = (c 2) e = (c 3) (d 1 + e 1)") == "7") # 3 + 4

  # Ok, but now we can do arguments so...
  assert(run("""
  factorial = func [:n > 0 if: [n * factorial (n - 1)] else: [1]]
  factorial 12
  """) == "479001600")

  # Implement simple for loop
  assert(run("""
  for = func [:n :m :blk
    x = n
    [x <= m] whileTrue: [
      do blk x
      x = (x + 1)]]
  r = 0
  for 2 5 [r = (r + :i)]
  eval r
  """) == "14")

  # Smalltalk do: in spry
  assert(run("""
    r = 0 y = [1 2 3]
    y do: [r = (r + :e)]
    eval r
  """) == "6")

  # Implementing detect:, note that we use the internal streaming of blocks
  # so we need to do call reset first. Also note the use of return which
  # is a non local return in Smalltalk style, so it will return from the
  # whole func.
  assert(run("""
    [1 2 3 4] detect: [:each > 2]
  """) == "3")

  # Implementing select:
  assert(run("""
    [1 2 3 4] select: [:each > 2]
  """) == "[3 4]")

  # Implementing collect: as do: and map:
  assert(run("""
  map: = funci [:blk :lambda
    result = []
    blk reset
    [blk end?] whileFalse: [
      result add: (do lambda (blk next)) ]
    ^ result ]
  [1 2 3 4] map: [:x * 2]
  """) == "[2 4 6 8]")

  # Reflection
  # The word locals gives access to the local Map
  assert(run("do [d = 5 locals]") == "{d = 5}")
  assert(run("do [d = 5 locals at: 'd]") == "5")
  assert(run("locals at: 'd put: 5 d + 2") == "7")
  assert(run("do [a = 1 b = 2 locals]") == "{a = 1 b = 2}")
  assert(run("do [a = 1 b = 2 c = 3 (locals)]") == "{a = 1 b = 2 c = 3}")

  # The word self gives access to the closest outer object
  assert(run("self") == "nil")
  assert(run("x = object [] {a = 1 foo = funci [self at: 'a]} x::foo") == "1")
  assert(run("x = object [] {a = 1 foo = funci [^ @a]} x::foo") == "1")
  assert(run("x = object [] {a = 1 foo = funci [^ @a]} eva $x::foo") == "funci [^ @a]")
  assert(run("x = object [foo bar] {a = 1} x tags") == "[foo bar object]")

  # The word activation gives access to the current activation record
  assert(run("activation") == "activation [[activation] 1]")

  # Add and check tag
  assert(run("x = 3 x tag: 'num x tag? 'num") == "true")
  assert(run("x = 3 x tag: 'num x tag? 'bum") == "false")
  assert(run("x = 3 x tag: 'num x tags") == "[num]")
  assert(run("x = 3 x tag? 'bum") == "false")
  assert(run("x = 3 x tags: [bum num] x tags") == "[bum num]")
  assert(run("x = 3 x tags: [bum num] x tag? 'bum") == "true")
  assert(run("x = 3 x tags: [bum num] x tag? 'lum") == "false")

  # spry math
  assert(run("10 fac") == "3628800")
  assert(run("10.0 sin") == "-0.5440211108893698")

  # spry polyfuncs (reduce should not be needed here)
  assert(run("p = polyfunc reduce [func [:a + 1] func [:x]]") == "polyfunc [func [:a + 1] func [:x]]")
  assert(run("[int string] -> [:x]") == "funci [:x]")
  assert(run("$([int string] -> [:x]) tags") == "[int string]")
  assert(run("p = polyfunc reduce [[int] -> [1] [string] -> [2]]") == "polyfunc [funci [1] funci [2]]")
  assert(run("p = polyfunc reduce [[int] -> [1] [string] -> [2]] 42 p") == "nil")
  assert(run("inc = polyfunc reduce [[int] -> [:x + 1] [string] -> [:x , \"c\"]] (42 tag: 'int) inc") == "43")
  assert(run("inc = polyfunc reduce [[int] -> [:x + 1] [string] -> [:x , \"c\"]] (\"ab\" tag: 'string) inc") == "\"abc\"")

  # spry compress
  assert(run("compress \"abc123\"") == "\"\\x06\\x00\\x00\\x00`abc123\"")
  assert(run("uncompress (compress \"abc123\")") == "\"abc123\"")

  # spry serialize parse
  assert(run("serialize [1 2 3 \"abc\" {3.14}]") == "\"[1 2 3 \\\"abc\\\" {3.14}]\"")
  assert(run("parse serialize [1 2 3 \"abc\" {3.14}]") == "[1 2 3 \"abc\" {3.14}]")

  # spry IO
  assert(run("(parse readFile \"data.spry\") first first") == "121412")

  # spry OS
  assert(run("shell \"stat --printf='%s' data.spry\"") == "\"1665\\x0A\"")

  # Library code
  assert(run("assert (3 < 4)") == "true")

  # Clone
  # Checks that we do get a clone, but a shallow one
  assert(run("a = [[1 2]] b = (a clone) (b at: 0) at: 0 put: 5 eval a") == "[[5 2]]")
  assert(run("a = [[1 2]] b = (a clone) b add: 5 eval a") == "[[1 2]]")
  assert(run("x = $(3 4) $x clone") == "(3 4)") # Works for Paren
  assert(run("x = ${3 4} $x clone") == "{3 4}") # Works for Curly
  assert(run("a = {x = 1} a clone") == "{x = 1}")
  assert(run("a = {x = [1]} b = (a clone) (b at: 'y put: 2) eval b") == "{x = [1] y = 2}")
  assert(run("a = {x = [1]} b = (a clone) (b at: 'y put: 2) eval a") == "{x = [1]}")

  # Modules
  assert(run("Foo = {x = 10} eva Foo::x") == "10")
  assert(run("Foo = {x = 10} eva Foo::y") == "undef")
  assert(run("Foo = {x = 10} Foo::x = 3 eva Foo::x") == "3")
  assert(run("eva Foo::y") == "undef")
  assert(run("Foo = {x = 10} eva $Foo::x") == "10")
  assert(run("Foo = {x = func [:x + 1]} eva $Foo::x") == "func [:x + 1]")
  assert(run("Foo = {x = func [:x + 1]} Foo::x 3") == "4")
  assert(run("eval modules") == "[]")
  assert(run("modules add: {x = 10} eval modules") == "[{x = 10}]")
  assert(run("modules add: {x = 10} eval modules size") == "1")
  assert(run("modules add: {x = 10} eval x") == "10")
  assert(run("Foo = {x = func [:x + 1]} Bar = {x = 7} modules add: Foo modules add: Bar x 1") == "2")
  assert(run("Foo = {x = func [:x + 1] y = 10} Bar = {x = func [:x + 2]} modules add: Bar modules add: Foo x y") == "12")
  assert(run("foo = func [bar = {x = 10} bar::x + 1] bar = 10 eval foo") == "11")
  assert(run("do [bar = {x = 1 y = 2} do [bar::x + 1]]") == "2")

  # String
  assert(run("\"abc.de\" split: \".\"") == "[\"abc\" \"de\"]")

  # Commented
  assert(stringRun("[  1 2  3 ] commented") == "[  1 2  3 ]")

  # This test ensures that the commented func produces the same
  # code string (comments and formatting) that the AST was built from.
  let code ="""[# A Map is just a bunch of assignments inside a Curly. A Curly in Spry is just a sequence of Nodes.
# After parsing we have a Curly which is still just "data". If we evaluate the Curly Spry will
# execute the code inside it and at the end return the Map of locals that was populated by the code.
{
  # First is a very minimal meta Map holding the name of the Module in
  # the form of a literal Word which is similar to a Symbol in Ruby/Smalltalk.
  # There is no mandatory information, nor is the meta Map itself mandatory.
  meta = { name = 'Foo }

  # This just assigns 13 to x in the local scope Map
  foo = 13

  # Same again, but we can of course have funcs or whatever in a Module
  adder = func [:x + :y]
}]"""
  assert(stringRun(code & " commented") == code)

  # Collections
  assert(run("x = 0 [1 2 3] do: [x = (x + :y)] eva x") == "6")
  assert(run("x = 0 1 to: 3 do: [x = (x + :y)] eva x ") == "6")
  assert(run("x = [] 1 to: 3 do: [x add: :y] eva x ") == "[1 2 3]")
when true:
  # Demonstrate extension from extend.nim
  assert(show("'''abc'''") == "\"abc\"")
  assert(run("reduce [1 + 2 3 + 4]") == "[3 7]")




