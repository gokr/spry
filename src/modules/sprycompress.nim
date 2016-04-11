import lz4
import spryvm

# Ni compression
proc addCompress*(spry: Interpreter) =
  # Compression of string
  nimPrim("compress", false, 1):
    newValue(compress(StringVal(evalArg(spry)).value, level=1))
  nimPrim("uncompress", false, 1):
    newValue(uncompress(StringVal(evalArg(spry)).value))
