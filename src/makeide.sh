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
nim --verbosity:2 -d:release --dynlibOverride:ui  --passL:"-rdynamic ./libui.a -lgtk-3 -lgdk-3 -lpangocairo-1.0 -lpango-1.0 -latk-1.0 -lcairo-gobject -lcairo -lgdk_pixbuf-2.0 -lgio-2.0 -lgobject-2.0 -lglib-2.0" c ide
strip -s ide
upx --best ide
