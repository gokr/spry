#!/bin/bash
export HERE="$(dirname "$(readlink -f "$0")")"

pushd $HERE/../src > /dev/null
nim js -r -d:release -d:nodejs sprytest
if [ $? -ne 0 ]; then
  echo "TEST FAILED"
  popd > /dev/null
  exit 1
fi
echo "ALL GOOD"
popd > /dev/null
exit 0
