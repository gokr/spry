import spryvm
import os, osproc

# Spry OS module
proc addOS*(spry: Interpreter) =
  nimPrim("sleep", false, 1):
    sleep(IntVal(evalArg(spry)).value)
  nimPrim("shell", false, 1):
    newValue(execProcess(StringVal(evalArg(spry)).value))
