import nivm, niparser
import os

# Ni OS module
proc addOS*(ni: Interpreter) =
  nimPrim("sleep", false, 1):
    sleep(IntVal(evalArg(ni)).value)
