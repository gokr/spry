# Trivial example of creating a Spry interpreter and have it run some code.

# Just import Spry
import spryvm

# Create an interpreter and have it evaluate a string of Spry code
echo newInterpreter().eval """[
  factorial = func [ifelse (:n > 0) [n * factorial (n - 1)] [1]]
  factorial 12
]"""
