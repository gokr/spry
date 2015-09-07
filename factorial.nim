# Trivial example of embedded Ni factorial
import ni

discard newInterpreter().eval """
  factorial = [ifelse (:n > 1) [n * factorial(n - 1)] [1]]
  echo(factorial 12)
"""
