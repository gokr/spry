#!./nirepl
# Run with: ./nirepl tutorial1.ni
#
# Ni source code is basically just a list of "words" and "values"
# with sublists created using "[..]" and such a list is called
# a "block". Parenthesis can also be used to control evalation
# order. This file, when parsed by the Parser, is wrapped in
# a block.
#
# This is a word followed by a value. It should print "Hello".
echo "Hello"
# pause

# Here is a block with all core Ni value types.
echo [3 4.0 true false nil "hey"]
# pause

# Running quit without any argument will fail because it needs one argument.
quit
# pause

# It fails quite miserably with a string too...
quit "foo"
# pause

# But with an exit code int it works fine
quit 0
# pause

