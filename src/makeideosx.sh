# Make executable from ide.sy
rm -f ide.nim
cat << EOF > ./ide.nim
# Spry IDE :)
import spryvm, spryio, spryoo, sprymodules, spryui
var spry = newInterpreter()
spry.addIO()
spry.addOO()
spry.addModules()
spry.addUI()
discard spry.eval("""[
EOF

cat ide.sy >> ./ide.nim

cat << EOF >> ./ide.nim
]""")
EOF

# Through experiments this builds libui statically linked
nim --verbosity:2 -d:release --dynlibOverride:ui  --passL:"-rdynamic ./libuiosx.a -lobjc -framework Foundation -framework AppKit" c ide
