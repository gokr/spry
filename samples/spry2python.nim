import spryvm/spryvm, spryvm/sprycore, spryvm/sprylib, spryvm/sprypython

# Create a Spry interpreter
var spry = newInterpreter()
spry.addCore()
spry.addLib()
spry.addPython()

# Let the interpreter execute some python code using the extension word
discard spry.eval("""[
python
"from time import time,ctime
print 'Today is',ctime(time())"
]""")
