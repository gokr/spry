import lz4
import spryvm

# Spry compression
proc addCompress*(spry: Interpreter) =
  # Compression of string
  nimPrim("compress", false):
    newValue(compress(StringVal(evalArg(spry)).value, level=1))
  nimPrim("uncompress", false):
    newValue(uncompress(StringVal(evalArg(spry)).value))
