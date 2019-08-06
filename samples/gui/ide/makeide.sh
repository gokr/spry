# Stop the script if a command fails 
set -e 
# Make executable from ide.sy
rm -f ide.nim
cat << EOF > ./ide.nim
# Spry IDE :)
import spryvm/spryvm

import spryvm/sprycore, spryvm/sprylib, spryvm/spryextend, spryvm/sprymath,
  spryvm/spryos, spryvm/spryio, spryvm/sprythread,
  spryvm/spryoo, spryvm/sprydebug, spryvm/sprycompress, spryvm/sprystring,
  spryvm/sprymodules, spryvm/spryreflect, spryvm/spryblock, spryvm/sprynet,
  spryvm/spryui, spryvm/spryjson, spryvm/sprysqlite

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
spry.addJSON()
spry.addSqlite()

discard spry.eval("""[
EOF

cat ide.sy >> ./ide.nim

cat << EOF >> ./ide.nim
]""")
EOF

nim c ide

# Strip
strip -s ide

# Use upx if we have it
command -v upxx >/dev/null 2>&1 && {
  upx --best ide
}

# Done
echo "Produced: ./ide"
file ide
