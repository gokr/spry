import ni, niparser
import math

# Ni math module

proc extendInterpreter(ni: Interpreter) {.procvar.} =
  nimPrim("sin", true, 1):
    newValue(sin(FloatVal(evalArgInfix(ni)).value))
  nimPrim("cos", true, 1):
    newValue(cos(FloatVal(evalArgInfix(ni)).value))

addInterpreterExtension(extendInterpreter)

