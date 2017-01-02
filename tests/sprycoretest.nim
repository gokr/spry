import unittest, spryvm, spryunittest

import sprycore, sprylib

suite "spry core":
  setup:
    let vm = newInterpreter()
    vm.addCore()
    vm.addLib()

  test "evaluation":
    # Parse properly, show renders the Node tree
    check show("[3 + 4]") == "[3 + 4]"
    # And run
    check run("3 + 4") == "7"
    # A block is just a block, no evaluation
    check run("[3 + 4]") == "[3 + 4]"
    # But we can use do to evaluate it
    check run("do [4 + 3]") == "7"
    # But we need to use func to make a closure from it
    check run("func [3 + 4]") == "func [3 + 4]"
    # Which will evaluate itself when being evaluated
    check run("'foo = func [3 + 4] foo") == "7"

  test "maps":
    check run("{}") == "{}"
    check run("{a = 1 b = 2}") == "{a = 1 b = 2}"
    check run("{a = 1 b = \"hey\"}") == "{a = 1 b = \"hey\"}"
    check run("{a = {d = (3 + 4) e = (5 + 6)}}") == "{a = {d = 7 e = 11}}"
    check run("{a = 3} at: 'a") == "3"
    check run("{3 = 4 6 = 1} at: 6") == "1" # int, In spry any Node can be a key!
    check run("{\"hey\" = 4 true = 1 6.0 = 8} at: \"hey\"") == "4" # string
    check run("{\"hey\" = 4 true = 1 6.0 = nil} at: 6.0") == "nil" # float
    #check run("{undef = 8} at: undef") == "8") # undef humm...
    #check run("{nil = 4} at: nil") == "4") # nil  humm...
    #check run("{true = false} at: true") == "false") # nil humm..
    check run("dict = {a = 3} dict at: 'a put: 5 dict at: 'a") == "5"

  test "assignment":
    check run("x = 5") == "5"
    check run("x = 5 x") == "5"
    check run("x = 5 eval x") == "5" # We can also eval it
    check run("f = func [3 + 4] f") == "7" # Functions are evaluated
    check run("Foo = {x = 5} Foo::x = 3 eval Foo") == "{x = 3}"

  test "nil and undef":
    # Nil vs undef, set? set:
    check run("eval x") == "undef"
    check run("x ?") == "false"
    check run("x nil?") == "false"
    check run("x = 1 x ?") == "true"
    check run("x = 1 x nil?") == "false"
    check run("x = nil x ?") == "true"
    check run("x = nil x nil?") == "true"
    check run("x = undef x ?") == "false"
    check run("x = undef x nil?") == "false"
    check run("x = 1 x = undef x ?") == "false"
    check run("'x set: 1 'x set: undef x set?") == "false"
    check run("x = 1 x set? then: [12]") == "12"
    check run("x = 5 x = undef eval x") == "undef"
    check run("x = 5 x = nil eval x") == "nil"
    check run("'x set: 5 eval x") == "5"
    check run("x = 'foo x set: 5 eval foo") == "5"
    check run("(litword \"foo\") set: 5 eval foo") == "5"

  test "basic math":
    # Precedence and basic math
    check run("3 * 4") == "12"
    check run("3 + 1.5") == "4.5"
    check run("5 - 3 + 1") == "3" # Left to right
    check run("3 + 4 * 2") == "14" # Yeah
    check run("3 + (4 * 2)") == "11" # Thank god
    check run("3 / 2") == "1.5" # Goes to float
    check run("3 / 2 * 1.2") == "1.8" #
    check run("3 + 3 * 1.5") == "9.0" # Goes to float

    # And we can nest also, since a block has its own Activation
    # Note that only last result of block is used so "1 + 7" is dead code
    check run("5 + do [3 + do [1 + 7 1 + 9]]") == "18"

  test "print":
    # print (like Rebol "form")
    check run("\"ab[c\"") == "\"ab[c\""
    check run("123 print") == "\"123\""
    check run("\"abc123\" print") == "\"abc123\""
    check run("[\"abc123\" 12] print") == "\"abc123 12\""

  test "concatenation":
    # Concatenation
    check run("\"ab\", \"cd\"") == "\"abcd\""
    check run("[1] , [2 3]") == "[1 2 3]"


  test "set and get":
    # Set and get variables
    check run("x = 4 5 + x") == "9"
    check run("x = 1 x = x eval x") == "1"
    check run("x = 4 x") == "4"
    check run("x = 1 x = (x + 2) eval x") == "3"
    check run("x = 4 k = do [y = (x + 3) eval y] k + x") == "11"
    check run("x = 1 do [..x = (x + 1)] eval x") == "2"

  test "parse":
    # Use parse word
    check run("parse \"[3 + 4]\"") == "[3 + 4]"
    check run("do parse \"[3 + 4]\"") == "7"

  test "booleans":
    # Boolean
    check run("true") == "true"
    check run("true not") == "false"
    check run("false") == "false"
    check run("false not") == "true"
    check run("3 < 4") == "true"
    check run("3 > 4") == "false"
    check run("(3 > 4) not") == "true"
    check run("false or false") == "false"
    check run("true or false") == "true"
    check run("false or true") == "true"
    check run("true or true") == "true"
    check run("false and false") == "false"
    check run("true and false") == "false"
    check run("false and true") == "false"
    check run("true and true") == "true"
    check run("3 > 4 or (3 < 4)") == "true"
    check run("3 > 4 and (3 < 4)") == "false"
    check run("7 > 4 and (3 < 4)") == "true"

  test "comparisons":
    # Comparisons
    check run("7 >= 4") == "true"
    check run("4 >= 4") == "true"
    check run("3 >= 4") == "false"
    check run("7 <= 4") == "false"
    check run("4 <= 4") == "true"
    check run("3 <= 4") == "true"
    check run("\"abc\" >= \"abb\"") == "true"
    check run("\"abc\" >= \"abc\"") == "true"
    check run("\"abc\" >= \"abd\"") == "false"
    check run("\"abc\" <= \"abb\"") == "false"
    check run("\"abc\" <= \"abc\"") == "true"
    check run("\"abc\" <= \"abd\"") == "true"

  test "equality and identity":
    check run("3 == 4") == "false"
    check run("4 == 4") == "true"
    check run("3.0 == 4.0") == "false"
    check run("4 == 4.0") == "true"
    check run("4.0 == 4") == "true"
    check run("4.0 != 4") == "false"
    check run("4.1 != 4") == "true"
    check run("\"abc\" == \"abc\"") == "true"
    check run("\"abc\" == \"AAA\"") == "false"
    check run("true == true") == "true"
    check run("false == false") == "true"
    check run("false == true") == "false"
    check run("true == false") == "false"
    check run("\"abc\" == \"abc\"") == "true"
    check run("\"abc\" == \"ab\"") == "false"
    check run("\"abc\" != \"ab\"") == "true"
    check run("true === true") == "true" # True for all singletons
    check run("nil === nil") == "true"
    check run("undef === undef") == "true"
    check run("'foo === 'foo") == "true" # Litwords are canonicalized
    check run("'foo == 'foo") == "true" # Words are equal
    check run("$(reify 'foo) == (reify 'foo)") == "true" # Words are equal
    check run("$(reify 'foo) == (reify '$foo)") == "true" # Words are equal
    check run("$(reify 'foo) === (reify 'foo)") == "false" # Other words are not canonicalized
    check run("1 === 1") == "false"
    check run("[1 2] == [1 2]") == "true"
    check run("[1 2] === [1 2]") == "false"
    check run("x = [1 2] y = x y === x") == "true"
    check run("[1 2] != [1]") == "true"
    check run("[1 2] == [1]") == "false"
    check run("[1 2] == [1]") == "false"

# Will cause type exceptions
#  check run("false == 4") == "false")
#  check run("4 == false") == "false")
#  check run("\"ab\" == 4") == "false")
#  check run("4 == \"ab\"") == "false")


  test "blocks":
    # Block indexing and positioning
    check run("[3 4] size") == "2"
    check run("[] size") == "0"
    check run("[3 4] at: 0") == "3"
    check run("[3 4] at: 1") == "4"
    check run("[3 4] at: 0 put: 5") == "[5 4]"
    check run("x = [3 4] x at: 1 put: 5 eval x") == "[3 5]"
    check run("x = [3 4] x add: 5 eval x") == "[3 4 5]"
    check run("x = [3 4] x removeLast eval x") == "[3]"
    check run("[3 4], [5 6]") == "[3 4 5 6]"
    check run("[3 4] contains: 3") == "true"
    check run("[3 4] contains: 8") == "false"
    check run("{x = 1 y = 2} contains: 'x") == "true"
    check run("{x = 1 y = 2} contains: 'z") == "false"
    check run("{\"x\" = 1 \"y\" = 2} contains: \"x\"") == "true"
    check run("{\"x\" = 1 \"y\" = 2} contains: \"z\"") == "false"
    check run("[false bum 3.14 4] contains: 'bum") == "true"
    check run("[1 2 true 4] contains: 'false") == "false" # Note that block contains words, not values
    check run("[1 2 true 4] contains: 'true") == "true"
    check run("x = false b = [] b add: x b contains: x") == "true"

    # copyFrom:to:
    check run("[1 2 3] copyFrom: 1 to: 2") == "[2 3]"
    check run("[1 2 3] copyFrom: 0 to: 1") == "[1 2]"
    check run("\"abcd\" copyFrom: 1 to: 2") == "\"bc\""

  test "homoiconicism":
    # Data as code
    check run("code = [1 + 2 + 3] code at: 2 put: 10 do code") == "14"

  test "conditionals":
    # then:, then:else:, unless:, unless:else:
    check run("x = true x then: [true]") == "true"
    check run("false then: [12]") == "nil"
    check run("x = false x then: [true]") == "nil"
    check run("(3 < 4) then: [\"yay\"]") == "\"yay\""
    check run("(3 > 4) then: [\"yay\"]") == "nil"
    check run("(3 > 4) then: [\"yay\"] else: ['ok]") == "'ok"
    check run("(3 > 4) then: [true] else: [false]") == "false"
    check run("(4 > 3) then: [true] else: [false]") == "true"
    check run("(3 < 4) then: [5]") == "5"
    check run("3 < 4 then: [5]") == "5"
    check run("3 < 4 else: [5]") == "nil"
    check run("3 < 4 then: [1] else: [2]") == "1"
    check run("3 < 4 else: [1] then: [2]") == "2"
    check run("5 < 4 else: [1] then: [2]") == "1"
    check run("5 < 4 then: [1] else: [2]") == "2"

  test "loops":
    # loops, eva will
    check run("x = 0 5 repeat: [..x = (x + 1)] x") == "5"
    check run("x = 0 0 repeat: [..x = (x + 1)] x") == "0"
    check run("x = 0 5 repeat: [..x = (x + 1)] x") == "5"
    check run("x = 0 [x > 5] whileFalse: [..x = (x + 1)] x") == "6"
    check run("x = 10 [x > 5] whileTrue: [..x = (x - 1)] x") == "5"
    check run("foo = func [x = 10 [x > 5] whileTrue: [x = (x - 1) ^11] ^x] foo") == "11" # Return inside
    check run("foo = func [x = 10 [x > 5 ^99] whileTrue: [x = (x - 1)] ^x] foo") == "99" # Return inside


  test "functions":
    # func
    check run("z = func [3 + 4] z") == "7"
    check run("x = func [3 + 4] eva $x") == "func [3 + 4]"
    check run("x = func [3 + 4] 'x") == "'x"
    check run("x = func [3 + 4 ^ 1 8 + 9] x") == "1"
    # Its a non local return so it returns all the way, thus it works deep down
    check run("x = func [3 + 4 do [ 2 + 3 ^ 1 1 + 1] 8 + 9] x") == "1"
    check run("x = method [3 + 4 do [2 + 3 ^(self + 1) + 1] 8 + 9] 9 x") == "10"
    check run("x = method [self < 4 then: [do [^9] 8] else: [^10]] 2 x") == "9"
    check run("do [:a] 5") == "5"
    check run("x = func [:a a + 1] x 5") == "6"
    check run("x = func [:a + 1] x 5") == "6" # Slicker than the above!
    check run("x = func [:a :b eval b] x 5 4") == "4"
    check run("x = func [:a :b a + b] x 5 4") == "9"
    check run("x = func [:a + :b] x 5 4") == "9" # Again, slicker
    check run("z = 15 x = func [:a :b a + b + z] x 1 2") == "18"
    check run("z = 15 x = func [:a + :b + z] x 1 2") == "18" # Slick indeed
    # Variadic and dynamic args
    # This func does not pull second arg if first is < 0.
    check run("add = func [ :a < 0 then: [^ nil] ^ (a + :b) ] add -4 3") == "3"
    check run("add = func [ :a < 0 then: [^ nil] ^ (a + :b) ] add 1 3") == "4"
    # Macros, they need to be able to return multipe nodes...
    check run("z = 5 foo = func [:$a ^ func [a + 10]] fupp = foo z z = 3 fupp") == "13"
    # func closures. Creates two different funcs closing over two values of a
    check run("c = func [:a func [a + :b]] d = (c 2) e = (c 3) (d 1 + e 1)") == "7" # 3 + 4

  test "ast manipulation":
    # Testing $ word that prevents evaluation, like quote in Lisp
    check run("x = $(3 + 4) $x at: 2") == "4"

    # Testing literal word evaluation into the real word
    #check run("eva 'a") == "a")
    #check run("eva ':$a") == ":$a")

  test "do":
    check run("do [:b + 3] 4") == "7" # Muhahaha!
    check run("do [:b + :c - 1] 4 3") == "6" # Muhahaha!
    check run("d = 5 do [:x] d") == "5"
    check run("d = 5 do [:$x] d") == "d"
    # x will be a Word, need val and key prims to access it!
    #check run("a = \"ab\" do [:$x ($x print), \"c\"] a") == "\"ac\"") # x becomes "a"
    check run("a = \"ab\" do [:x , \"c\"] a") == "\"abc\"" # x becomes "ab"

  test "scoping":
    # @ and ..
    check run("d = 5 do [eval $d]") == "5"
    check run("d = 5 do [eval $@d]") == "undef"
    check run("d = 5 do [eval $..d]") == "5"
    check run("d = 5 do [d = 3 $..d + d]") == "8"
    check run("d = 5 do [eval d]") == "5"
    check run("d = 5 do [eval @d]") == "undef"
    check run("d = 5 do [eval ..d]") == "5"
    check run("d = 5 do [d = 3 ..d + d]") == "8"

  # func infix works too, and with 3 or more arguments too...
  test "methods":
    check run("xx = func [:a :b a + b + b] xx 2 (xx 5 4)") == "28" # 2 + (5+4+4) + (5+4+4)
    check run("xx = method [:b self + b] 5 xx 2") == "7" # 5 + 7
    check run("xx = method [self + :b] 5 xx 2") == "7" # 5 + 7
    check run("xx = method [:b self + b + b] 5 xx (4 xx 2)") == "21" # 5 + (4+2+2) + (4+2+2)
    check run("xx = method [self + :b + b] (5 xx 4) xx 2") == "17" # 5+4+4 + 2+2
    check run("pick2add = method [:b :c self at: b + (self at: c)] [1 2 3] pick2add 0 2") == "4" # 1+3
    check run("pick2add = method [self at: :b + (self at: :c)] [1 2 3] pick2add 0 2") == "4" # 1+3

  test "misc":
    # Ok, but now we can do arguments so...
    check run("""
    factorial = func [:n > 0 then: [n * factorial (n - 1)] else: [1]]
    factorial 12
    """) == "479001600"

    # Implement simple for loop
    check run("""
    for = func [:n :m :blk
    x = n
    [x <= m] whileTrue: [
      do blk x
      ..x = (x + 1)]]
    r = 0
    for 2 5 [..r = (r + :i)]
    eval r
    """) == "14"

    check run("""
    r = 0 y = [1 2 3]
    y do: [..r = (r + :e)]
    eval r
    """) == "6"

  test "reflection":
    # The word locals gives access to the local Map
    check run("do [d = 5 locals]") == "{d = 5}"
    check run("do [d = 5 locals at: 'd]") == "5"
    check run("locals at: 'd put: 5 d + 2") == "7"
    check run("map = do [a = 1 b = 2 locals] (map at: 'a) + (map at: 'b) ") == "3"
    check run("map = do [a = 1 b = 2 c = 3 (locals)] (map get: a) + (map get: b) + (map get: c)") == "6"

  test "self":
    # The word self gives access to the receiver for methods only
    check run("self") == "undef" # self not bound for funcs
    check run("xx = func [self] xx") == "undef" # self not bound for funcs
    check run("xx = method [self + self] o = 12 o xx") == "24" # Multiple self
    check run("xx = method [node] foo xx") == "foo" # Access to unevaled self
    check run("xx = method [node at: 0] $(3 + 4) xx") == "3" # Access to unevaled self
    check run("[] add: 1 ; add: $ + ; add: 2 echo ; do ;") == "3" # Access to last self ;

    check run("x = object [] {a = 1 foo = method [self at: 'a]} x::foo") == "1"
    check run("x = object [] {a = 1 foo = method [^ @a]} x::foo") == "1"
    check run("x = object [] {a = 1 foo = method [^ @a]} eva $x::foo") == "method [^ @a]"
    check run("x = object ['foo 'bar] {a = 1} x tags") == "['foo 'bar 'object]"

  test "cascade":
    # The word ; gives access to the last known infix argument
    check run("[1] add: 2 ; add: 3 ; size") == "3"

  test "activation":
    # The word activation gives access to the current activation record
    check run("activation") == "activation [[activation] 1]"

  test "tags":
    # Add and check tag
    check run("x = 3 x tag: 'num x tag? 'num") == "true"
    check run("x = 3 x tag: 'num x tag? 'bum") == "false"
    check run("x = 3 x tag: 'num x tags") == "['num]"
    check run("x = 3 x tag? 'bum") == "false"
    check run("x = 3 x tags: ['bum 'num] x tags") == "['bum 'num]"
    check run("x = 3 x tags: ['bum 'num] x tag? 'bum") == "true"
    check run("x = 3 x tags: ['bum 'num] x tag? 'lum") == "false"

    # spry serialize parse
  test "serialize":
    check run("serialize [1 2 3 \"abc\" {3.14}]") == "\"[1 2 3 \\\"abc\\\" {3.14}]\""
    check run("parse serialize [1 2 3 \"abc\" {3.14}]") == "[1 2 3 \"abc\" {3.14}]"

  test "lib":
    # Library code
    check run("assert (3 < 4)") == "true"

  test "clone":
    check run("a = 12 b = (a clone) a = 9 eva b") == "12"
    check run("a = \"abc\" b = (a clone) a = \"zzz\" eva b") == "\"abc\""
    check run("a = [[1 2]] b = (a clone) (b at: 0) at: 0 put: 5 eval a") == "[[5 2]]"
    check run("a = [[1 2]] b = (a clone) b add: 5 eval a") == "[[1 2]]"
    check run("x = $(3 4) $x clone") == "(3 4)" # Works for Paren
    check run("x = ${3 4} $x clone") == "{3 4}" # Works for Curly
    check run("a = {x = 1} a clone") == "{x = 1}"
    check run("a = {x = [1]} b = (a clone) (b at: (reify 'y) put: 2) (b get: y) + ((b get: x) at: 0) ") == "3"
    check run("a = {x = [1]} b = (a clone) (b set: y to: 2) (b get: y) + ((b get: x) at: 0)") == "3"
    check run("a = {x = [1]} b = (a clone) (b set: y to: 2) (a get: y)") == "undef"

  test "modules":
    # Modules
    check run("Foo = {x = 10} eva Foo::x") == "10" # Direct access works
    check run("Foo = {x = 10} eva Foo::y") == "undef" # and missing key works too
    check run("Foo = {x = 10} Foo::x = 3 eva Foo::x") == "3"
    check run("eva Foo::y") == "undef"
    check run("Foo = {x = 10} eva $Foo::x") == "10"
    check run("Foo = {x = func [:x + 1]} eva $Foo::x") == "func [:x + 1]"
    check run("Foo = {x = func [:x + 1]} Foo::x 3") == "4"
    check run("eval modules") == "[]"
    check run("modules add: {x = 10} eval modules") == "[{x = 10}]"
    check run("x") == "10"
    check run("foo = func [bar = {x = 10} bar::x + 1] bar = 10 eval foo") == "11"
    check run("do [bar = {x = 1 y = 2} do [bar::x + 1]]") == "2"
  test "modules lookup":
    check run("Foo = {x = func [:x + 1]} Bar = {x = 7} modules add: Foo modules add: Bar x 1") == "2"
  test "modules lookup 2":
    check run("Foo = {x = func [:x + 1] y = 10} Bar = {x = func [:x + 2]} modules add: Bar modules add: Foo x y") == "12"

  test "iteration":
    check run("x = 0 [1 2 3] do: [..x = (x + :y)] x") == "6"
    check run("x = 0 1 to: 3 do: [..x = (x + :y)] x ") == "6"
    check run("y = [] -2 to: 2 do: [y add: :n] y") == "[-2 -1 0 1 2]"
    check run("x = [] 1 to: 3 do: [x add: :y] x ") == "[1 2 3]"

  test "map":
    # Maps and Words, all variants should end up as same key
    check run("map = {x = 1} map at: 'x put: 2 map at: (reify '$x) put: 3 map at: (reify ':x) put: 4 eval map") == "{:x = 4}"

  test "various tricks":
    # Implementing prefix minus
    check run("mm = func [0 - :n] mm 7 + 2") == "-5"

    # Implementing ifTrue: using then:, two variants
    check run("ifTrue: = method [:blk self then: [^do blk] else: [^nil]] 3 > 2 ifTrue: [99] ") == "99"
    check run("ifTrue: = method [:blk self then: [^do blk] nil] 1 > 2 ifTrue: [99] ") == "nil"
