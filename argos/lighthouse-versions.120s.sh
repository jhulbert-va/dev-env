#!/usr/bin/env bash

MEH=":radio_button:"
FAIL=":red_circle:"

VERSIONS=$(mktemp "/tmp/versions.argosXXX")

onExit() { rm $VERSIONS; }
trap onExit EXIT

# =~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~

deployed-versions \
  -a data-query \
  >> $VERSIONS

FAIL_COUNT=$(awk '/^[a-z-]*:.*/ {print $0}' $VERSIONS \
                 | grep -c -i 'test failures')

if [ "$FAIL_COUNT" != 0 ]; then
  echo "$FAIL"
else
  echo "$MEH"
fi
echo "---"
cat $VERSIONS

exit 0
