import spryvm
import os

# Spry OS module
proc addOS*(spry: Interpreter) =
  nimPrim("sleep", false, 1):
    sleep(IntVal(evalArg(spry)).value)
