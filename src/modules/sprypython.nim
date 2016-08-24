import spryvm, python

proc primPython*(spry: Interpreter): spryvm.Node =
  initialize()
  discard runSimpleString(StringVal(evalArg(spry)).value)
  finalize()

# This proc does the work extending an Interpreter instance
proc addPython*(spry: Interpreter) =
  spry.makeWord("python", newPrimFunc(primPython))

