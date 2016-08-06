import spryvm

import strutils

# Spry string module
proc addString*(spry: Interpreter) =
  nimPrim("split:", true):
    let s = StringVal(evalArgInfix(spry)).value
    let sep = StringVal(evalArg(spry)).value
    # Should probably be a converter
    let blk = newBlok()
    for token in s.split(sep):
      blk.add(newValue(token))
    return blk
