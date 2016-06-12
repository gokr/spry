import spryvm
import math, random

# Spry math module
proc addMath*(spry: Interpreter) =
  # math module
  nimPrim("binom", true, 2): newValue(binom(IntVal(evalArgInfix(spry)).value, IntVal(evalArg(spry)).value))
  nimPrim("fac", true, 1): newValue(fac(IntVal(evalArgInfix(spry)).value))
  nimPrim("powerOfTwo?", true, 1): newValue(isPowerOfTwo(IntVal(evalArgInfix(spry)).value))
  nimPrim("nextPowerOfTwo", true, 1): newValue(nextPowerOfTwo(IntVal(evalArgInfix(spry)).value))
  # nimPrim("sum", false, 1): newValue(sum(SeqComposite(evalArg(spry)).value))
  nimPrim("random", true, 1):
    let max = evalArgInfix(spry)
    if max of FloatVal:
      return newValue(random(FloatVal(max).value))
    else:
      return newValue(random(IntVal(max).value))
  nimPrim("sqrt", true, 1): newValue(sqrt(FloatVal(evalArgInfix(spry)).value))
  nimPrim("sin", true, 1): newValue(sin(FloatVal(evalArgInfix(spry)).value))
  nimPrim("cos", true, 1): newValue(cos(FloatVal(evalArgInfix(spry)).value))
