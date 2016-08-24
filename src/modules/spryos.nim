import spryvm
import os, osproc, times

# Spry OS module
proc addOS*(spry: Interpreter) =
  nimFunc("sleep"):
    sleep(IntVal(evalArg(spry)).value)
  nimFunc("shell"):
    newValue(execProcess(StringVal(evalArg(spry)).value))
  nimMeth("timeToRun"):
    var t = cpuTime()
    discard evalArgInfix(spry).evalDo(spry)
    newValue(cpuTime() - t)
