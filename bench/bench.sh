rm -f ./niv2 ./ni
nim c -d:release --out:$PWD/ni ../src/ni.nim
nim c -d:release --gc:v2 --out:$PWD/niv2 ../src/ni.nim

echo
echo "Ni with default gc:"
/usr/bin/time -v ./ni factorial.ni
echo
echo "Ni using nimath fac primitive function:"
/usr/bin/time -v ./ni fac.ni

# v2 fails currently with "in loop" or something
echo "Ni with default gc v2:"
/usr/bin/time -v ./niv2 fac.ni

