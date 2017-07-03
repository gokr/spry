# Spry interpreter doing eval in a browser.

import spryvm

import sprycore, spryextend, sprymath, spryoo, sprydebug, sprystring, sprymodules,
 spryreflect, spryblock, sprybrowser

var spry = newInterpreter()

spry.addCore()
spry.addExtend()
spry.addMath()
#spry.addOS()
#spry.addIO()
#spry.addThread()
#spry.addPython()
spry.addOO()
spry.addDebug()
#spry.addCompress()
spry.addString()
spry.addModules()
spry.addReflect()
#spry.addRawUI()
spry.addBlock()
spry.addBrowser()

proc spryEval*(code: cstring): cstring {.exportc.} =
  $spry.evalRoot("[" & $code & "]")

when isMainModule and not defined(js):
  echo spryEval("[3 + 4]")

