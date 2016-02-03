# Trivial example of creating a Ni interpreter with an added
# interpreter extension module called nireduce

# Base Ni interpreter
import nivm

# A sample interpreter extension that adds a reduce primitive
# and support for triple single quote multiline string literals
import niextend, niio

# Try out reduce which evaluates and collects all expressions in a block
var ni = newInterpreter()
ni.addExtend()
ni.addIO()
discard ni.eval """
  echo reduce [1 + 2 3 + 4]
"""
