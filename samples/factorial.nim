# Trivial example of creating a Ni interpreter and have it run some code.

# Just import ni.
import nivm

# Create an interpreter and have it evaluate a string of Ni code
discard newInterpreter().eval """
  factorial = func [ifelse (:n > 0) [n * factorial (n - 1)] [1]]
  echo factorial 12
"""
