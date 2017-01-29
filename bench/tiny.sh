rm -f ./spryclang ./spry
nim c -d:release --out:$PWD/spry ../src/spry.nim
nim c -d:release --cc:clang --out:$PWD/spryclang ../src/spry.nim

echo "Spry with gcc, tiny.sy"
./spry tiny.sy
echo
echo "Spry with clang, tiny.sy"
./spryclang tiny.sy
echo
