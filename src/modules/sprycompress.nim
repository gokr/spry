import snappy
import spryvm

# Spry compression
proc addCompress*(spry: Interpreter) =
  # Compression of string
  nimFunc("compress"):
    newValue(compress(StringVal(evalArg(spry)).value))
  nimFunc("uncompress"):
    newValue(uncompress(StringVal(evalArg(spry)).value))
