# Trivial example of creating a function that is implemented by
# running eval in a Ni interpreter.

# Just import ni.
import nivm, niparser

# Create an interpreter and have it evaluate a string of Ni code
proc factorial*(n: int): int {.exportc.} =
  IntVal(newInterpreter().eval("""
    factorial = func [ifelse (:n > 0) [n * factorial (n - 1)] [1]]
    factorial """ & $n)).value
