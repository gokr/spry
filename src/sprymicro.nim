# Spry Micro Language interpreter.
#
# This interpreter has no extra modules linked, only core language and
# it doesn't even import os in order to access a given Spry source file.

import spryvm

# Just run an embedded string
discard newInterpreter().eval("[echo (3 + 4)]")
