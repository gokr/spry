# Trivial example of creating a function that is implemented by
# running eval in a Spry interpreter.

# Just import Spry and core
import spryvm, sprycore

# Create an interpreter and have it evaluate a string of code
proc factorial*(n: int): int {.exportc.} =
  let vm = newInterpreter()
  vm.addCore()
  IntVal(vm.eval("""[
    factorial = func [:n > 0 then: [n * factorial (n - 1)] else: [1]]
    factorial """ & $n & "]")).value
