#!/usr/bin/env bash

ICONS="$(dirname $(readlink -f $0))/icons"
MEH="$(base64 -w 0 $ICONS/blue-target.ico)"
FAIL="$(base64 -w 0 $ICONS/red-target.ico)"

VERSIONS=$(mktemp "/tmp/versions.argosXXX")

onExit() { rm $VERSIONS; }
trap onExit EXIT

# =~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~

deployed-versions \
  -a data-query \
  -a fall-risk \
  >> $VERSIONS

FAIL_COUNT=$(awk '/^[a-z-]*:.*/ {print $0}' $VERSIONS \
                 | grep -c -i 'test failures')

if [ "$FAIL_COUNT" != 0 ]; then
  echo "| image='$FAIL' imageWidth=21"
else
  echo "| image='$MEH' imageWidth=21"
fi
echo "---"
cat $VERSIONS

exit 0
