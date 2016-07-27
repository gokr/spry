#!/bin/bash
export HERE="$(dirname "$(readlink -f "$0")")"

pushd $HERE/../src > /dev/null
nim c -r sprytest
if [ $? -ne 0 ]; then
  echo "TEST FAILED"
  popd
  exit 1
fi
echo "ALL GOOD"
popd > /dev/null
exit 0
