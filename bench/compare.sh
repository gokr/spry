./factorial.sh
echo
echo "Rebol3:"
/usr/bin/time -v ./r3 factorial.r
echo
echo "Python:"
/usr/bin/time -v python factorial.py
