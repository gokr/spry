#!/bin/bash
export HERE="$(dirname "$(readlink -f "$0")")"

# Core Spry
echo "***************  Core Spry implementation **************"
cloc --exclude-dir=nimcache --read-lang-def=$HERE/cloc-nim $HERE/../src
echo
echo
echo

# Spry extra modules
echo "***************  Spry modules  **************"
cloc --exclude-dir=nimcache --read-lang-def=$HERE/cloc-nim $HERE/../src/modules
echo
echo
echo

# The rest
echo "***************  Samples, tutorials, bench **************"
cloc --exclude-ext=js --exclude-dir=nimcache --read-lang-def=$HERE/cloc-nim $HERE/../samples $HERE/../tutorials $HERE/../bench
echo
echo
echo


