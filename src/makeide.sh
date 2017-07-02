# Make executable from ide.sy
rm -f ide.nim
cat << EOF > ./ide.nim
# Spry IDE :)

import spryvm, sprycore, sprylib, spryextend, sprymath, spryos, spryio, sprythread,
 spryoo, sprydebug, sprycompress, sprystring, sprymodules, spryreflect,
 spryblock, sprynet, spryrawui

var spry = newInterpreter()

# Add extra modules
spry.addCore()
spry.addExtend()
spry.addMath()
spry.addOS()
spry.addIO()
spry.addThread()
spry.addOO()
spry.addDebug()
spry.addCompress()
spry.addString()
spry.addModules()
spry.addReflect()
spry.addBlock()
spry.addNet()
spry.addLib()
spry.addRawUI()

discard spry.eval("""[
EOF

cat ide.sy >> ./ide.nim

cat << EOF >> ./ide.nim
]""")
EOF

# Through experiments this builds libui statically linked
nim --verbosity:2 -d:release --dynlibOverride:ui  --passL:"-rdynamic ../lib/libui.a -lgtk-3 -lgdk-3 -lpangocairo-1.0 -lpango-1.0 -latk-1.0 -lcairo-gobject -lcairo -lgdk_pixbuf-2.0 -lgio-2.0 -lgobject-2.0 -lglib-2.0" c ide

# Strip
strip -s ide

# Use upx if we have it
command -v upxx >/dev/null 2>&1 && {
  upx --best ide
}

# Done
echo "Produced: ./ide"
file ide
