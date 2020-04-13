#!/usr/bin/env bash

cd ~

ON=" • "
OFF="◦"

APP=$(find -name 'bulk-fhir')
DEV_APP=$(readlink -f "$APP/run-local.sh")

stopApp() {
  echo "--stop | bash='$DEV_APP' param1='-$1' param2='stop' terminal=false"
}

stopDocker() {
  echo "--stop | bash='docker stop $1' terminal=false"
}

appStatus() {
  [ -n "$1" ] && APPS+="$ON" || APPS+="$OFF"
}

KONG=$(docker ps -f publish=8443/tcp -q)
ARGONAUT=$(lsof -ti tcp:8090 -s tcp:listen)
DQDB=$(docker ps -q -f name='dqdb')
BULK=$(lsof -ti tcp:8091 -s tcp:listen)
FALL_RISK=$(lsof -ti tcp:8070 -s tcp:listen)
FACILITIES_DB=$(docker ps -q -f name='facilities-cdw-db')

[ -z "${KONG}${ARGONAUT}${DQDB}${BULK}${FALL_RISK}${FACILITIES_DB}" ] && echo "-|trim=false" && exit 0

#appStatus "$KONG"
#appStatus "DQDB"
#appStatus "$IDS"
#appStatus "$BULK"
#appStatus "$FALL_RISK"

echo ":cd:"
echo "---"

[ -n "$KONG" ] && echo "Kong ($KONG)" && "--stop | bash='docker stop $KONG' terminal=false"

[ -n "$ARGONAUT" ] && echo "Data Query ($ARGONAUT)" && stopApp d

[ -n "$DQDB" ] && echo "DQDB ($DQDB)" && stopDocker $DQDB 

[ -n "$BULK" ] && echo "Bulk Fhir ($BULK)"

[ -n "$FALL_RISK" ] && echo "Fall Risk ($FALL_RISK)" && stopApp f

[ -n "$FACILITIES_DB" ] && echo "Facilities DB ($FACILITIES_DB)" && stopDocker $FACILITIES_DB
