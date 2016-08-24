import lz4
import spryvm

# Spry compression
proc addCompress*(spry: Interpreter) =
  # Compression of string
  nimFunc("compress"):
    newValue(compress(StringVal(evalArg(spry)).value, level=1))
  nimFunc("uncompress"):
    newValue(uncompress(StringVal(evalArg(spry)).value))
