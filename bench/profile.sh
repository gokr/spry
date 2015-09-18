nim c --profiler:on --stackTrace:on --out:$PWD/nip ../src/ni.nim
./nip factorial.ni
less profile_results.txt
