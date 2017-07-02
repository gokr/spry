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
nim --verbosity:2  --dynlibOverride:ui  --passL:"-rdynamic ../../lib/libui.a -lgtk-3 -lgdk-3 -lpangocairo-1.0 -lpango-1.0 -latk-1.0 -lcairo-gobject -lcairo -lgdk_pixbuf-2.0 -lgio-2.0 -lgobject-2.0 -lglib-2.0" c editor
#nim --verbosity:2 -d:release --dynlibOverride:ui  --passL:"-rdynamic ../../lib/libui.a -lgtk-3 -lgdk-3 -lpangocairo-1.0 -lpango-1.0 -latk-1.0 -lcairo-gobject -lcairo -lgdk_pixbuf-2.0 -lgio-2.0 -lgobject-2.0 -lglib-2.0" c editor

# Strip
strip -s editor

# Use upx if we have it
command -v upxx >/dev/null 2>&1 && {
  upx --best editor
}

# Done
echo "Produced: ./editor"
file editor

