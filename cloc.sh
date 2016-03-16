# Core Ni
echo "***************  Core Ni implementation **************"
cloc --exclude-dir=nimcache --read-lang-def=cloc-nim src
echo
echo
echo

# Ni extra modules
#echo "***************  Ni modules  **************"
#cloc --exclude-dir=nimcache --read-lang-def=cloc-nim src
#echo
#echo
#echo

# The rest
echo "***************  Samples, tutorials, bench **************"
cloc --exclude-ext=js --exclude-dir=nimcache --read-lang-def=cloc-nim samples tutorials bench
echo
echo
echo


