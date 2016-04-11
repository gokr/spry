import spryvm, python

proc primPython*(spry: Interpreter): spryvm.Node =
  Py_Initialize()
  discard PyRun_SimpleString(StringVal(evalArg(spry)).value)
  Py_Finalize()

# This proc does the work extending an Interpreter instance
proc addPython*(spry: Interpreter) =
  spry.makeWord("python", newNimProc(primPython, false, 1))

