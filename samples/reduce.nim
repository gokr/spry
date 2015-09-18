# Trivial example of creating a Ni interpreter with an added
# interpreter extension module called nireduce

# Base Ni interpreter
import ni

# A sample interpreter extension that adds a reduce primitive
# and support for triple single quote multiline string literals
import niextend

# Try out reduce which evaluates and collects all expressions in a block
discard newInterpreter().eval """
  echo reduce [1 + 2 3 + 4]
"""
