# Silly example of adding Nim prims to Ni so that a Ni script can make
# calls into a Nim library. This can also be hooked into newInterpreter()
# like its done in extend.nim, but I wanted to be more direct in this
# sample.
import ni, niparser

# Create a Ni interpreter
let n = newInterpreter()

# Get us the root Context where we can register primitives
let root = n.root

# Create a Nim side data structure we want to use from Ni
var s:seq[string] = @["a", "b"]

# Bind a NimProc to the word "nimpush" that will simply take an argument
# which is a string and add it to the seq.
discard root.bindit("nimpush", newNimProc(
  # Every NimProc returns a Node, note that arguments will be
  # pulled from inside the Nim code by calling the Interpreter
  proc (ni: Interpreter): Node =
    # Call Interpreter to evaluate and return next arg which is a Node
    let arg = ni.evalArg()
    # arg is a Node so we convert to StringVal and call
    # value to get the wrapped string
    let str = StringVal(arg).value
    # Finally we run Nim code! Yiha!
    s.add(str)
    # Let's just return nil to Ni, its a singleton Node that the Interpreter has
    return ni.nilVal
, false, 1))

echo "Before running Ni script we have: " & $s
# Call Interpreter with a Ni script
discard n.eval("nimpush (\"a\" & \"b\")")
# Verify glory
echo "After Ni script we have: " & $s


# Call Interpreter with a Ni script that tries pushing an integer, we will get
# proper Nim exceptions which we can handle
try:
  discard n.eval("nimpush 123")
except ObjectConversionError:
  echo "Ooops!"

