# Compile spry.nim to spry.js
nim js -d:release --out:spry.js spry.nim
command -v minify >/dev/null 2>&1 || {
  echo
  echo "******************************************"
  echo "No minify installed, skipping minification"
  exit 0
}
minify -o spry.js spry.js
