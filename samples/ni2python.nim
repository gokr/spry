import ni, nipython

# Create a Ni interpreter
let n = newInterpreter()

# Let the Ni interpreter execute some python code using the nipython extension word
discard n.eval("""
python
"from time import time,ctime
print 'Today is',ctime(time())"
""")
