import spryvm

import strutils

# Spry string module, depends on sprycore.nim
proc addString*(spry: Interpreter) =
  nimMeth("split:"):
    let s = StringVal(evalArgInfix(spry)).value
    let sep = StringVal(evalArg(spry)).value
    # Should probably be a converter
    let blk = newBlok()
    for token in s.split(sep):
      blk.add(newValue(token))
    return blk
  nimMeth("replace:with:"):
    let self = StringVal(evalArgInfix(spry))
    let sub = StringVal(evalArg(spry)).value
    let by = StringVal(evalArg(spry)).value
    self.value = replace(self.value, sub, by)
    return self
  #nimMeth("find:"):
  #  let self = StringVal(evalArgInfix(spry))
  #  let sub = StringVal(evalArg(spry)).value
  #  newValue(find(self, sub))
  nimMeth("findString:startingAt:"):
    let self = StringVal(evalArgInfix(spry)).value
    let sub = StringVal(evalArg(spry)).value
    let start = IntVal(evalArg(spry)).value
    newValue(find(self, sub, start))

  # This should be a Module, right? String
  discard spry.evalRoot """[
    findString: = method [self findString: :s startingAt: 0]
  ]"""
