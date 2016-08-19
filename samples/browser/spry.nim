# Spry interpreter doing eval in a browser.

import spryvm

import spryextend, sprymath, spryoo, sprydebug, sprystring, sprymodules,
 spryreflect

var vm = newInterpreter()
vm.addDebug()
vm.addExtend()
vm.addMath()
vm.addOO()
vm.addString()
vm.addModules()
vm.addReflect()

proc spryEval*(code: cstring): cstring {.exportc.} =
  $vm.evalRoot("[" & $code & "]")

when isMainModule and not defined(js):
  echo spryEval("[3 + 4]")

