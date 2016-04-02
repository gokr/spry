# Ni interpreter doing eval in a browser.
# Can be evolved into a trivial REPL-in-a-browser.

import nivm, niparser, nidebug

var vm = newInterpreter()
vm.addDebug()

proc nieval*(code: cstring): cstring {.exportc.} =
  $vm.evalRoot($code)

when isMainModule and not defined(js):
  echo nieval("3 + 4")

