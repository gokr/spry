# Silly example of adding Nim prims to Spry so that a Spry script can make
# calls into a Nim library. This can also be hooked into newInterpreter()
# like its done in extend.nim, but I wanted to be more direct in this
# sample.
import spryvm, sprycore, sprylib

# Create an interpreter and add core and lib
let spry = newInterpreter()
spry.addCore()
spry.addLib()

# Create a Nim side data structure we want to use from Spry
var s:seq[string] = @["a", "b"]

# Bind a PrimFunc to the word "nimpush" that will simply take an argument
# which is a string and add it to the seq.
spry.makeWord("nimpush", newPrimFunc(
  # Every PrimFunc returns a Node, note that arguments will be
  # pulled from inside the Nim code by calling the Interpreter
  proc (spry: Interpreter): Node =
    # Call Interpreter to evaluate and return next arg which is a Node
    let arg = spry.evalArg()
    # arg is a Node so we convert to StringVal and call
    # value to get the wrapped string
    let str = StringVal(arg).value
    # Finally we run Nim code! Yiha!
    s.add(str)
    # Let's just return nil to Spry
    # It's a singleton Node that the Interpreter has
    return spry.nilVal
))

echo "Before running Spry script we have: " & $s
# Call Interpreter with a script
discard spry.eval("[nimpush \"c\"]")
# Verify glory
echo "After Spry script we have: " & $s


# Call Interpreter with a Spry script that tries pushing an integer,
# we will get proper Nim exceptions which we can handle
try:
  discard spry.eval("nimpush 123")
except ObjectConversionError:
  echo "Yes, we got a proper exception when trying to push an integer. Cool!"

