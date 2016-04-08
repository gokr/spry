rm -f ./ni
nim -d:release --opt:size --passL:-static --gcc.exe:musl-gcc --gcc.linkerexe:musl-gcc c --out:$PWD/spry ../src/sprymin.nim && strip -s $PWD/spry

echo
echo "Spry min built with musl-libc:"
/usr/bin/time -v ./spry factorial.sy
echo
echo "Spry min using nimath fac primitive function:"
/usr/bin/time -v ./spry fac.sy

