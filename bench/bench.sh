rm -f ./spryv2 ./spry
nim c -d:release --out:$PWD/spry ../src/spry.nim
nim c -d:release --gc:v2 --out:$PWD/spryv2 ../src/spry.nim

echo
echo "Spry with default gc:"
/usr/bin/time -v ./spry factorial.sy
echo
echo "Spry using nimath fac primitive function:"
/usr/bin/time -v ./spry fac.sy

# v2 fails currently with "in loop" or something
echo "Spry with default gc v2:"
/usr/bin/time -v ./spryv2 fac.sy

