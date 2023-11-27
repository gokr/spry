# Compile fact.nim to fact.js
nim js -d:release --out:fact.js fact.nim
command -v uglifyjs >/dev/null 2>&1 || {
  echo
  echo "******************************************"
  echo "No uglify-js installed, skipping minification"
  exit 0
}
uglifyjs --compress --mangle -o fact.js -- fact.js
