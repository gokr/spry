# Compile fact.nim to fact.js
nim js -d:release --out:fact.js fact.nim
command -v minify >/dev/null 2>&1 || {
  echo
  echo "******************************************"
  echo "No minify installed, skipping minification"
  exit 0
}
minify -o fact.js fact.js

