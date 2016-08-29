import spryvm
import os, osproc, times

# Spry OS module
proc addOS*(spry: Interpreter) =
  nimFunc("sleep"):
    sleep(IntVal(evalArg(spry)).value)
  nimFunc("shell"):
    newValue(execProcess(StringVal(evalArg(spry)).value))
  nimMeth("cpuTimeToRun"):
    var t = cpuTime()
    discard evalArgInfix(spry).evalDo(spry)
    newValue((cpuTime() - t) * 1000 ) # Milliseconds
  nimMeth("timeToRun"):
    var t = epochTime()
    discard evalArgInfix(spry).evalDo(spry)
    newValue((epochTime() - t) * 1000 ) # Milliseconds
