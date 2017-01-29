import spryvm, modules/spryio
let spry = newInterpreter()
spry.addIO()
discard spry.eval """[
  echo "Hello World"
]"""

