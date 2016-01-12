# Trivial example of creating a Ni interpreter and have it run some code.

# Just import ni.
import ni, niparser

# Create an interpreter and have it evaluate a string of Ni code
proc factorial*(n: int): int {.exportc.} =
  IntVal(newInterpreter().eval("""
    factorial = func [ifelse (:n > 0) [n * factorial (n - 1)] [1]]
    factorial """ & $n)).value
