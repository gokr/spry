# Trivial example of creating a Spry interpreter and have it run some code.

# Just import Spry
import spryvm, sprycore, sprylib

# Create an interpreter and add core and lib
let spry = newInterpreter()
spry.addCore()
spry.addLib()

# Eval some spry code
echo spry.eval """[
  factorial = func [:n > 0 then: [n * factorial (n - 1)] else: [1]]
  factorial 12
]"""
