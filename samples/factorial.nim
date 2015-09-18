# Trivial example of embedded Ni factorial
import ni

discard newInterpreter().eval """
  factorial = func [ifelse (:n > 0) [n * factorial (n - 1)] [1]]
  echo (factorial 12)
"""
