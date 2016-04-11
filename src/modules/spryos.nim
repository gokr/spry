import spryvm
import os

# Ni OS module
proc addOS*(spry: Interpreter) =
  nimPrim("sleep", false, 1):
    sleep(IntVal(evalArg(spry)).value)
