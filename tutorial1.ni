#!./nirepl
#
# Ni is a crazy little mix of Rebol/Smalltalk/Self/Lisp/Forth and Nim. Kinda.
#
# This tutorial is a valid Ni program with interspersed "# pause" lines that
# the nirepl will detect and pause. You can hit "s" to suspend and do what
# you wish, and then later type in a single "c" to continue. Any command
# or Ni code will be executed when you enter an empty line (hit enter twice).
#
# pause
# But hey, let's get cracking with some code...
#
# Ni is homoiconic which means that code and data share the same syntax.
# Ni code is basically just a list of "words" and "values" separated
# by whitespace. Like the word "echo" followed by a string literal:
echo "hello"
# pause

# Ni is, like Nim, a language where there is no class concept - 
#
# The word "echo" is a core word in Ni, but its not a keyword - its rather a
# Ni standard library function. All words in Ni's vocabulary can be redefined.
#
# There are three singleton values familiar to Smalltalkers which we can reach
# via three core words.
echo [true false nil]
# pause

# Ni uses square brackets a lot (just like Smalltalk/Self) for control structures
# but also for making ordered sequences like "[1 2 3]" and such a sequence is
# called a "block".
echo([1 2 3] len)
# pause

# Parenthesis can also be used to control evalation
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

# But with an exit code int it works fine
quit 0
# pause
