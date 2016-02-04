rm -f ./ni
nim -d:release --opt:size --passL:-static --gcc.exe:musl-gcc --gcc.linkerexe:musl-gcc c --out:$PWD/ni ../src/nimin.nim && strip -s $PWD/ni

echo
echo "Ni min built with musl-libc:"
/usr/bin/time -v ./ni factorial.ni
echo
echo "Ni min using nimath fac primitive function:"
/usr/bin/time -v ./ni fac.ni

