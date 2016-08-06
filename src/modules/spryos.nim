import spryvm
import os, osproc, times

# Spry OS module
proc addOS*(spry: Interpreter) =
  nimPrim("sleep", false):
    sleep(IntVal(evalArg(spry)).value)
  nimPrim("shell", false):
    newValue(execProcess(StringVal(evalArg(spry)).value))
  nimPrim("timeToRun", true):
    var t = cpuTime()
    discard evalArgInfix(spry).evalDo(spry)
    newValue(cpuTime() - t)
