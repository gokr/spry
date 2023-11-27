# Compile spry.nim to spry.js
nim js -d:release --out:spry.js spry.nim
command -v uglifyjs >/dev/null 2>&1 || {
  echo
  echo "******************************************"
  echo "No uglify-js installed, skipping minification"
  exit 0
}
uglifyjs --compress --mangle -o spry.js -- spry.js
