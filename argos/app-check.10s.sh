#!/usr/bin/env bash

APP_INFO=$(mktemp "/tmp/app-check.argosXXX")
APP=$(find ~ -name "bulk-fhir")
DEV_APP=$(readlink -f "$APP/run-local.sh")

onExit() { rm $APP_INFO; }
trap onExit EXIT

javaApp() {
  local app=$1
  local short=$2  
  local pid=$3
  [ -z "$pid" ] && return
  echo -e "$app ($pid)\n--stop | bash='$DEV_APP' param1='--$short' param2='stop' terminal=false" >> $APP_INFO
}

dockerContainer() {
  local name=$1
  local container=$2
  [ -z "$container" ] && return
  echo -e "$name ($container)\n--stop | bash='docker stop $container' terminal=false" >> $APP_INFO
}

# Bulk-Fhir
javaApp "bulk" b $(lsof -ti tcp:8091 -s tcp:listen)
# Data-Query
dockerContainer "dqdb" $(docker ps -q -f name=dqdb)
javaApp "data-query" d $(lsof -ti tcp:8090 -s tcp:listen)
# Facilities
dockerContainer "facilities-cdw-db" $(docker ps -q -f name='facilities-cdw-db')
javaApp "facilities" f $(lsof -ti tcp:8085 -s tcp:listen)
javaApp "facilities-collector" c $(lsof -ti tcp:8080 -s tcp:listen)
javaApp "facilities-mock-services" m $(lsof -ti tcp:8666 -s tcp:listen)
# Fall-Risk
javaApp "fall-risk" "NOPE" $(lsof -ti tcp:8070 -s tcp:listen)
# Kong
docker container "kong" $(docker ps -f publish=8443/tcp -q)

[ "$(wc -l $APP_INFO | cut -d ' ' -f1)" == "0" ] && echo "-|trim=false" && exit 0

echo ":cd:"
echo "---"
cat $APP_INFO

exit 0
