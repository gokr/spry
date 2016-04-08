import spryvm
import math

# Ni math module
proc addMath*(ni: Interpreter) =
  # math module
  nimPrim("binom", true, 2): newValue(binom(IntVal(evalArgInfix(ni)).value, IntVal(evalArg(ni)).value))
  nimPrim("fac", true, 1): newValue(fac(IntVal(evalArgInfix(ni)).value))
  nimPrim("powerOfTwo?", true, 1): newValue(isPowerOfTwo(IntVal(evalArgInfix(ni)).value))
  nimPrim("nextPowerOfTwo", true, 1): newValue(nextPowerOfTwo(IntVal(evalArgInfix(ni)).value))
  # nimPrim("sum", false, 1): newValue(sum(SeqComposite(evalArg(ni)).value))
  nimPrim("random", true, 1):
    let max = evalArgInfix(ni)
    if max of FloatVal:
      return newValue(random(FloatVal(max).value))
    else:
      return newValue(random(IntVal(max).value))
  nimPrim("sqrt", true, 1): newValue(sqrt(FloatVal(evalArgInfix(ni)).value))
  nimPrim("sin", true, 1): newValue(sin(FloatVal(evalArgInfix(ni)).value))
  nimPrim("cos", true, 1): newValue(cos(FloatVal(evalArgInfix(ni)).value))
