import nivm, nipython

# Create a Ni interpreter
var ni = newInterpreter()
ni.addPython()

# Let the Ni interpreter execute some python code using the nipython extension word
discard ni.eval("""
python
"from time import time,ctime
print 'Today is',ctime(time())"
""")
