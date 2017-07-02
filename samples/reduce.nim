# Trivial example of creating a Spry interpreter and adding
# two extension modules to it

# Base interpreter, core and lib
import spryvm, sprycore, sprylib

# A sample interpreter extension that adds a reduce primitive
# and support for triple single quote multiline string literals
import spryextend

# We also import IO to get echo support
import spryio

# Try out reduce which evaluates and collects all expressions in a block
var sp = newInterpreter()
sp.addCore()
sp.addLib()
sp.addExtend()   # Needed for reduce
sp.addIO()       # Needed for echo
discard sp.eval """[
  echo reduce [1 + 2 3 + 4]
]"""
