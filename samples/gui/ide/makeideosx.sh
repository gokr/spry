# Make executable from ide.sy
rm -f ide.nim
cat << EOF > ./ide.nim
# Spry IDE :)
import spryvm/spryvm

import spryvm/sprycore, spryvm/sprylib, spryvm/spryextend, spryvm/sprymath,
  spryvm/spryos, spryvm/spryio, spryvm/sprythread,
  spryvm/spryoo, spryvm/sprydebug, spryvm/sprycompress, spryvm/sprystring,
  spryvm/sprymodules, spryvm/spryreflect, spryvm/spryblock, spryvm/sprynet,
  spryvm/spryrawui, spryvm/spryjson, spryvm/sprysqlite

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
spry.addJSON()
spry.addSqlite()

discard spry.eval("""[
EOF

cat ide.sy >> ./ide.nim

cat << EOF >> ./ide.nim
]""")
EOF

# Through experiments this builds libui statically linked
nim --verbosity:2 --dynlibOverride:ui  --passL:" ../lib/libuiosx.a -lobjc -framework Foundation -framework AppKit" c ide.nim
mv ide ideosx
