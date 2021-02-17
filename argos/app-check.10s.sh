#!/usr/bin/env bash

APP_INFO=$(mktemp "/tmp/app-check.argosXXX")

trap "rm ${APP_INFO}" EXIT

dockerContainers() {
  local containerId
  for container in $(docker ps --format "{{.Names}}({{.ID}})")
  do
    containerId=$(echo ${container} | sed 's/.*(\(.*\))/\1/')
    echo -e "${container}\n--stop | bash='docker stop ${containerId}' terminal=false" >> $APP_INFO
  done
}

javaApplications() {
  local appPid
  for app in $(jps -v | awk '/-Dapp\.name=/ {print $1" "$3}' | sed 's/\([0-9]*\) -Dapp\.name=\(.*\)/\2(\1)/')
  do
    appPid=$(echo ${app} | sed 's/.*(\(.*\))/\1/')
    echo -e "${app}\n--stop | bash='kill ${appPid}' terminal=false" >> $APP_INFO
  done
}

dockerContainers
javaApplications

[ "$(wc -l ${APP_INFO} | cut -d ' ' -f1)" == "0" ] && echo "-|trim=false" && exit 0

echo ":rocket:"
echo "---"
cat $APP_INFO

exit 0
