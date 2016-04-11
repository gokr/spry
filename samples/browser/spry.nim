# Spry interpreter doing eval in a browser.

import spryvm, sprydebug

var vm = newInterpreter()
vm.addDebug()

proc spryEval*(code: cstring): cstring {.exportc.} =
  $vm.evalRoot("[" & $code & "]")

when isMainModule and not defined(js):
  echo spryEval("[3 + 4]")

