# Spry Micro Language interpreter.
#
# This interpreter has no extra modules linked, only core language.

import spryvm

# Just run an embedded string
discard newInterpreter().eval("[echo (3 + 4)]")
