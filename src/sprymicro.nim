# Ni Micro Language interpreter.
#
# This Ni interpreter has no extra modules linked, only core language.

import nivm

# Just run an embedded string
discard newInterpreter().eval("echo (3 + 4)")
