# Trivial example of creating a function that is implemented by
# running eval in a Spry interpreter.

# Just import Spry
import spryvm

# Create an interpreter and have it evaluate a string of code
proc factorial*(n: int): int {.exportc.} =
  IntVal(newInterpreter().eval("""[
    factorial = func [:n > 0 then: [n * factorial (n - 1)] else: [1]]
    factorial """ & $n & "]")).value
