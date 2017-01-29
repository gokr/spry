nim c --profiler:on --stackTrace:on --out:$PWD/spryp ../src/spry.nim
./spryp $1
less profile_results.txt
