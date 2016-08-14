import spryvm
import math, random

# Spry math module
proc addMath*(spry: Interpreter) =
  # Just like in Smalltalk
  nimPrim("negated", true):
    let v = evalArgInfix(spry)
    if v of FloatVal:
      return newValue(-FloatVal(v).value)
    else:
      return newValue(-IntVal(v).value)
  nimPrim("binom", true): newValue(binom(IntVal(evalArgInfix(spry)).value, IntVal(evalArg(spry)).value))
  nimPrim("fac", true): newValue(fac(IntVal(evalArgInfix(spry)).value))
  nimPrim("powerOfTwo?", true): newValue(isPowerOfTwo(IntVal(evalArgInfix(spry)).value))
  nimPrim("nextPowerOfTwo", true): newValue(nextPowerOfTwo(IntVal(evalArgInfix(spry)).value))
  # nimPrim("sum", false): newValue(sum(SeqComposite(evalArg(spry)).value))
  nimPrim("random", true):
    let max = evalArgInfix(spry)
    if max of FloatVal:
      return newValue(random(FloatVal(max).value))
    else:
      return newValue(random(IntVal(max).value))
  nimPrim("sqrt", true): newValue(sqrt(FloatVal(evalArgInfix(spry)).value))
  nimPrim("sin", true): newValue(sin(FloatVal(evalArgInfix(spry)).value))
  nimPrim("cos", true): newValue(cos(FloatVal(evalArgInfix(spry)).value))
