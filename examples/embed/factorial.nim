# Trivial example of creating a Spry interpreter and have it run some code.

# Just import Spry
import spryvm/spryvm, spryvm/sprycore, spryvm/sprylib, spryvm/spryio

# Create an interpreter and add core and lib
let spry = newInterpreter()
spry.addCore()
spry.addLib()
spry.addIO()

# Eval some spry code
echo spry.eval """[
  factorial = func [:n > 0 then: [n * factorial (n - 1)] else: [1]]

  echo "Factorial of 12 = "
  echo (factorial 12)
  quit 0
]"""
