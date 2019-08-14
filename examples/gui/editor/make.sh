# Make editor executable from editor.sy
#
# This trivial bash script just wraps up the Spry code in a Nim executable
# with the code embedded as a Nim string. Below we pick the Spry modules
# we need, then we create an Interpreter, add the modules to it, and then
# eval the code.

rm -f editor.nim
cat << EOF > ./editor.nim

import spryvm/spryvm, spryvm/sprycore,
 spryvm/spryos, spryvm/spryio, spryvm/sprystring,
 spryvm/spryblock, spryvm/spryui

var spry = newInterpreter()

# Add extra modules
spry.addCore()
spry.addOS()
spry.addIO()
spry.addString()
spry.addBlock()
spry.addUI()

discard spry.eval("""[
EOF
cat editor.sy >> ./editor.nim
cat << EOF >> ./editor.nim
]""")
EOF

# Build it
nim c editor.nim

# Strip
strip -s editor

# Use upx if we have it
command -v upxx >/dev/null 2>&1 && {
  upx --best editor
}

# Done
echo "Produced: ./editor"
file editor

