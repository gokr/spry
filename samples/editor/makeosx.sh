# Make editor executable from editor.sy
#
# This trivial bash script just wraps up the Spry code in a Nim executable
# with the code embedded as a Nim string. Below we pick the Spry modules
# we need, then we create an Interpreter, add the modules to it, and then
# eval the code.

rm -f editor.nim
cat << EOF > ./editor.nim

import spryvm, sprycore, sprylib, spryextend, spryos, spryio,
 spryoo, sprydebug, sprystring, sprymodules, spryreflect,
 spryblock, spryrawui

var spry = newInterpreter()

# Add extra modules
spry.addCore()
spry.addExtend()
spry.addOS()
spry.addIO()
spry.addOO()
spry.addDebug()
spry.addString()
spry.addModules()
spry.addReflect()
spry.addBlock()
spry.addLib()
spry.addRawUI()

discard spry.eval("""[
EOF
cat editor.sy >> ./editor.nim
cat << EOF >> ./editor.nim
]""")
EOF

# Through experiments this builds libui statically linked
nim --verbosity:2 --dynlibOverride:ui  --passL:" ../../lib/libuiosx.a -lobjc -framework Foundation -framework AppKit" c editor.nim

# Done
echo "Produced: ./editor"
file editor

