nim c -d:release --out:$PWD/ni ../src/ni.nim
nim c -d:release --gc:v2 --out:$PWD/niv2 ../src/ni.nim

echo
echo "Ni with default gc:"
time ./ni factorial.ni
# v2 fails currently with "in loop" or something
# echo "Ni with default gc v2:"
# time ./niv2 factorial.ni

rm -f ./niv2 ./ni
