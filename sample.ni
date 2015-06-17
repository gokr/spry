#!./ni
# Run with: ./ni sample.ni

# Fun Fun with Ni!

# Ni source code is basically just a list of "words" and "values"
# with sublists created using "[..]" and such a list is called
# a "block". Parenthesis can also be used to control evalation
# order. This file, when parsed by the Parser, is wrapped in
# a block.

# This is a word followed by a value. It should print "Hello".
echo "Hello"

# Here is a block with all core Ni value types.
# It should print "[3 4.0 true false nil "hey"]"
echo [3 4.0 true false nil "hey"]

# A word is just a string until it gets resolved. "echo" above
# got resolved to a primitive function taking 1 argument, when
# this script was called upon to run. It resolved only one
# level deep though, so the words "true", "false" and "nil"
# are still just words in the block above. When they are resolved
# they would refer to the singletons for those three values.

# "myblock:" below is a so called set-word, it means set the word
# "myblock" to refer to whatever comes to the left.
# Currently Ni only has global variables. So after this line
# "myblock" refers to a block with two value nodes and one
# word node - "+". But the "+" is not yet resolved.
myblock: [3 + 4]

# When the echo function pulls in its argument, it first evaluates
# it. For words it means "look up and evaluate what we found".
# We found a block, but blocks just return themselves when called
# upon to evaluate. We need to do more to actually "run" them.
# It should print "[3 + 4]" 
echo myblock

# The "do" word will resolve the block and then run it as code.
# Its at this point that "+" gets resolved to a primitive infix function.
# It should print "7".
echo do myblock

# But we can also turn a block into a function using the "func" function.
# Func takes a block as argument and turns it into a closure.
# Arguments are pulled using so called ArgWords, ">a".
# Let's turn myblock into a function and assign it to "foo".
foo: func myblock

# Now we can run it just with "foo" because a function will run
# when we evaluate it. It should print "7".
echo foo

# The Ni Parser is exposed through the "parse" primitive.
# Currently parse will put whatever it parses into a block
# so we don't need "[]" inside the string. The bar func we create
# below is equivalent to foo.
bar: func parse "3 + 4"

# So this should also print "7"
echo bar

# The fact that Ni code is just blocks means we can compose and manipulate
# code just as data. First let's make a func calling our previous funcs.
combo: func [foo + bar]

# It should print "14"
echo combo

# Now let's manipulate the combo func. It is actually a block containing
# the spec and body block. To get the func itself and not what it evaluates
# to we can use a get-word, which is the word with a ":" prefix.
# This should thus print the combo func itself: "[[foo + bar]]"
echo :combo

# So... blocks are collections
echo myblock len 	# Prints 3
echo myblock first 	# Prints 3
echo myblock at 1 	# Prints +

# ..and also positionable streams
echo myblock pos	# Prints 0
echo myblock read	# Gets the element at pos, prints 3
echo myblock next	# Gets the element at pos, increment pos, prints 3
echo myblock next	# Gets the element at pos, increment pos, prints +
echo myblock write 6	# Writes 6 at current pos, which is 2, prints myblock itself
echo do myblock 	# Prints 9
echo foo                # Prints 9 too, since.. you know, foo is a func of myblock


# Fetch func, pick out body, put in "20" at position 2 so that
# it now reads [foo + 20]
:combo first put 2 20
echo :combo

# Should print 27....nah, 29!
echo combo
