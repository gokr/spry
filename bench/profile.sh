nim c --profiler:on --stackTrace:on --out:$PWD/spryp ../src/spry.nim
./spryp coll.sy
less profile_results.txt
