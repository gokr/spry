#!./ni
# Run with: ./ni sample.ni

# Fun Fun with Ni!

# Ni source code is basically just a list of "words" and "values"
# with sublists created using "[..]" and such a list is called
# a "block". Parenthesis can also be used to control evalation
# order.

# This is a word followed by a value. It should print "Hello".
echo "Hello"

# A block is just data. Here we see all core Ni datatypes.
# It should print "[3 4.0 true false nil "hey"]"
echo [3 4.0 true false nil "hey"]

# A word is just a string until it gets resolved. "echo" above
# got resolved to a primitive function taking 1 argument, when
# this script was called upon to run. It resolved only one
# level deep.

# "myblock:" is a so called set-word, it means set the word
# "myblock" to refer to whatever comes to the left.
# Currently Ni only has global variables. So after this
# "myblock" refers to a block with two value nodes and one
# word node - "+". But the "+" is not yet resolved.
myblock: [3 + 4]

# When the echo function pulls in its argument, it first evaluates
# it. For words it means "look up and evaluate what we found".
# We found a block, but blocks just return themselves when called
# upon to evaluate. We need to do more to actually "run" them.
# It should print "[3 + 4]" 
echo myblock

# The "do" word will resolve and also run the code that the block
# contains. Its at this point that "+"
# gets resolved to a primitive infix function.
# It should print "7"
echo do myblock

# But we can perform the resolve operation ourselves and turn
# a block into a function without calling it, using "func".
# Let's assign the func to "foo"
foo: func myblock

# Now we can run it just with "foo" because a function will run
# when we evaluate it. It should print "7"
echo foo

# The Ni Parser is also exposed through the "parse" primitive.
# Currently parse will put whatever it parses into a block
# so we don't need "[]" inside the string.
bar: func parse "3 + 4"

# So this should also print "7"
echo bar

# Ni is homoiconic so we can compose and do other weirdo stuff
combo: func [foo + bar]

# It should print "14"
echo combo
