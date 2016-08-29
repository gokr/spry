rm -f ./spryclang ./spry
nim c -d:release --out:$PWD/spry ../src/spry.nim
nim c -d:release --cc:clang --out:$PWD/spryclang ../src/spry.nim

echo
echo "Spry with gcc, factorial.sy"
/usr/bin/time -v ./spry factorial.sy
echo
echo "Spry with clang, factorial.sy"
/usr/bin/time -v ./spryclang factorial.sy
echo
echo "Spry using nimath fac primitive function:"
/usr/bin/time -v ./spry fac.sy
