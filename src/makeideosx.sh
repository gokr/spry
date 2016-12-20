# Make executable from ide.sy
rm -f ide.nim
cat << EOF > ./ide.nim
# Spry IDE :)
import spryvm, sprycore, sprylib, spryextend, sprymath, spryos, spryio, sprythread,
 spryoo, sprydebug, sprycompress, sprystring, sprymodules, spryreflect,
 spryblock, sprynet, spryui

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
spry.addUI()

discard spry.eval("""[
EOF

cat ide.sy >> ./ide.nim

cat << EOF >> ./ide.nim
]""")
EOF

# Through experiments this builds libui statically linked
nim --verbosity:2 --dynlibOverride:ui  --passL:" ./libuiosx.a -lobjc -framework Foundation -framework AppKit" c ide.nim
mv ide ideosx
