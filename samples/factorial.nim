# Trivial example of creating a Spry interpreter and have it run some code.

# Just import Spry
import spryvm

# Create an interpreter and have it evaluate a string of Spry code
echo newInterpreter().eval """[
  factorial = func [:n > 0 if: [n * factorial (n - 1)] else: [1]]
  factorial 12
]"""
