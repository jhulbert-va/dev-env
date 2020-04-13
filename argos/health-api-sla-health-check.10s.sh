#!/usr/bin/env bash

BASE_PATH='services/fhir/v0/dstu2'
HEALTH_CHECK_PATH="$BASE_PATH/Patient/$MPATIENT"
LAB_CHECKS=("Patient/$MPATIENT")
PROD_CHECKS=("Patient/$MPATIENT" "Condition?patient=$MPATIENT" "MedicationStatement?patient=$MPATIENT" )

# Default to UP
HEALTH='UP'
lab='UP'
prod='UP'

# =========================================================

curlMagicPatient() {
  local status=$(curl -s -w "%{http_code}" -o /dev/null -H "Authorization: Bearer $MTOKEN" "$1")

  if [ "$status" != '200' ]
  then
    HEALTH='DOWN'
    echo "DOWN"
  fi
}

determineColor() {
  case $1 in
    UP) echo "green";;
    DOWN) echo "red";;
    *) echo "yellow";;
  esac
}

upOrDown() {
  if [ "$2" == "DOWN" ]
  then
    echo "DOWN"
  else
    echo "$1"
  fi
}

forEachHealthCheck() {
  for check in "$2"
  do
    [ "$(curlMagicPatient $1/$BASE_PATH/$check)" == "DOWN" ] && return "DOWN"
  done
}

lab=$(upOrDown "$lab" $(curlMagicPatient "https://dev-api.va.gov/$HEALTH_CHECK_PATH"))
prod=$(upOrDown "$prod" $(forEachHealthCheck "https://api.va.gov/" "${PROD_CHECKS[@]}"))

case "$(determineColor $HEALTH)" in
  green) echo ":smile:";;
  red) echo ":angry:";;
  *) echo ":cold_sweat:";;
esac
echo "---"

printf "%-11s %s | color=$(determineColor $prod) trim=false font=monospace\n" "production" "$prod"
printf "%-11s %s | color=$(determineColor $lab) trim=false font=monospace\n" "lab" "$lab"
