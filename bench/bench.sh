nim c -d:release --out:$PWD/ni ../src/ni.nim
echo "Ni:"
time ./ni factorial.ni
