#!/usr/bin/env bash

# https://tools.health.dev-developer.va.gov/jenkins/job/department-of-veterans-affairs/job/health-apis-deployer/job/qa/lastCompletedBuild/artifact/status.us-gov-west-1a.json

#
# The app you want to show a detailed view of (colors and stuff)
#
DETAIL_APP="data-query"

#
# Icon Locations
#
ICONS="$(dirname $(readlink -f $0))/icons"
FAIL="$(base64 -w 0 $ICONS/red-ci.ico)"
BEHIND="$(base64 -w 0 $ICONS/yellow-ci.ico)"
OKAY="$(base64 -w 0 $ICONS/green-ci.ico)"

#
# List of Environments
#
ENVS=( qa uat staging production staging_lab lab )
QA=0
UAT=1
STAGING=2
PROD=3
STAGING_LAB=4
LAB=5

typeset -a DATES
typeset -a APP_VERSION
typeset -a DU_VERSION
typeset -a TEST
typeset -a OK

# =========================================================
# Functions that'll make our lives easier...
# =========================================================

forEachEnv() {
  for i in $QA $UAT $STAGING $PROD $STAGING_LAB $LAB
  do
    ENV="${ENVS[$i]}"
    [ "${HAS_UAT}" == "false" ] && [ "$ENV" == "uat" ] && continue
    $@
  done
}

pullStatusArtifact() {
  HTTP_STATUS=$(curl -s -w "%{http_code}" -o "/tmp/health-apis-$ENV.status" --user $JENKINS_USERNAME_PASSWORD \
    "https://tools.health.dev-developer.va.gov/jenkins/job/department-of-veterans-affairs/job/health-apis-deployer/job/${ENV}/lastSuccessfulBuild/artifact/status.us-gov-west-1a.json")

  if [ "$HTTP_STATUS" != '200' ]
  then
    curl -s -w "%{http_code}" -o "/tmp/health-apis-$ENV.status" --user $JENKINS_USERNAME_PASSWORD \
    "https://tools.health.dev-developer.va.gov/jenkins/job/department-of-veterans-affairs/job/health-apis-deployer/job/${ENV}/lastSuccessfulBuild/artifact/status.us-gov-west-1b.json" \
    > /dev/null
  fi
}

simplePrint() {
  local app_version="${APP_VERSION[$i]}"
  local du_version="${DU_VERSION[$i]}"
  local tests="${TEST[$i]}"

  # Pad so everything lines up (dropdowns dont like fonts, colors, etc.)
  case "$ENV" in
    qa) pad='  .  .  .  .  .  .  .  .  .  ';;
    uat) pad='   .  .  .  .  .  .  .  .  ';;
    staging) pad=' .  .  .  .  .  .  ';;
    production) pad='   .  .  .  ';;
    staging_lab) pad='  .  .  .  ';;
    lab) pad=' .  .  .  .  .  .  .  .  .  ';;
    *) pad="";;
  esac

  if [ "$app_version" == "unknown" ] && [ "$du_version" == "unknown" ] && [ "$tests" == "unknown" ]
  then
    [ "$ENV" != "uat" ] && printf "%s unknown" "$ENV$pad" && echo -n "\n"
  else
    printf "%s %s   %s   %s" "$ENV$pad" "$du_version" "$app_version" "$tests"
    echo -n "\n"
  fi
}

appInfoDropdown() {
  local app="$1"
  printf "\n$app\n--"
  forEachEnv "saveAppData $app"
  forEachEnv "simplePrint $app"
}

isBehind() {
  local lower=$1
  local upper=$2
  [ "${DU_VERSION[$lower]}" != "${DU_VERSION[$upper]}" ] && OK[$lower]=false && let NUMBER_BEHIND+=1
}

reformatDate() {
  if [ "$1" != "unknown" ]
  then
    date=$(echo "$1" | sed -e 's/-0400//' -e 's/-/\//g')
    echo $(date --date="$date" +'%m/%d/%Y %H:%M' | sed 's/\//-/g')
  else
    echo $1
  fi
}

deets() {
  local env=$1
  local pre=$2
  local color='color=green '
  [ ${OK[$env]} != true ] && color="color=yellow "
  [ "${TEST[$env]}" != PASSED ] && color="color=red "
  printf "[ %-11s ][ %10s ][ %11s ][ %10s ][ %16s ]|trim=false ${color}font=monospace\n" \
         ${ENVS[$env]} ${DU_VERSION[$env]} ${APP_VERSION[$env]} ${TEST[$env]} "${DATES[$env]}"
}

printInTechnicolor() {
  printf "[ %-11s ][ %10s ][ %11s ][ %10s ][ %-16s ]|trim=false color=#cccccc font=monospace\n" \
           "Environment" "Deployment" "Application" "Test Suite" "Deployment Date"
  deets $QA

  if [ "${HAS_UAT}" == "true" ]
  then
    deets $UAT $QA
    deets $STAGING $UAT
  else
    deets $STAGING $QA
  fi

  deets $PROD $STAGING
  deets $STAGING_LAB $QA
  deets $LAB $STAGING_LAB
}

saveAppData() {
  OK[$i]=true
  METADATA=( $(cat /tmp/health-apis-$ENV.status \
    | jq -r ".[] | select(.[\"deployment-unit\"] == \"$1\")| .[\"deployment-date\"], .[\"deployment-app-version\"], .[\"deployment-unit-version\"], .[\"deployment-test-status\"] " \
    2> /dev/null ) )
  DATES[$i]="${METADATA[0]:-unknown}"
  APP_VERSION[$i]="${METADATA[1]:-unknown}"
  DU_VERSION[$i]="${METADATA[2]:-unknown}"
  TEST[$i]="${METADATA[3]:-unknown}"

  [ "$ENV" == "uat" ] \
    && [ "${APP_VERSION[$i]}" == "unknown" ] \
    && [ "${DU_VERSION[$i]}" == "unknown" ] \
    && HAS_UAT="false"
}

determineResults() {
  if [ "${OK[$i]}" != true ]
  then
    ALL_UP_TO_DATE=false
    [ -n "$UP_TO_DATE_MESSAGE" ] && UP_TO_DATE_MESSAGE+=", "
    UP_TO_DATE_MESSAGE+="${ENVS[$i]}"
  fi
  if [ "${TEST[$i]}" != PASSED ]
  then
    let NUMBER_OF_FAILURES+=1
    ALL_PASSED=false
    [ -n "$PASSED_MESSAGE" ] && PASSED_MESSAGE+=", "
    PASSED_MESSAGE+="${ENVS[$i]}"
  fi
}

# =========================================================
# The actual script
# =========================================================

HAS_UAT="true"

# Curling over and over again takes a long time. Lets do it just one time.
forEachEnv "pullStatusArtifact"

DETAIL_APP=${DETAIL_APP:-}

DROPDOWN_APPS=$(cat /tmp/health-apis-qa.status | jq -r '.[]."deployment-unit"' | grep -v "$DETAIL_APP" | paste -sd ' ')

if [ -n "$DETAIL_APP" ]
then
  forEachEnv "saveAppData $DETAIL_APP"

  NUMBER_BEHIND=0


  if [ "${HAS_UAT}" == "true" ]
  then
    isBehind $UAT $QA
    isBehind $STAGING $UAT
  else
    isBehind $STAGING $QA
  fi
  isBehind $PROD $STAGING
  isBehind $STAGING_LAB $QA
  isBehind $LAB $STAGING_LAB

  ALL_UP_TO_DATE=true
  ALL_PASSED=true
  UP_TO_DATE_MESSAGE=
  PASSED_MESSAGE=
  NUMBER_OF_FAILURES=0

  forEachEnv "determineResults"

  #
  # Determine message to be displayed in top-bar
  #
  if [ $ALL_PASSED == false ]
  then
    [ $NUMBER_OF_FAILURES == 1 ] && have=has || have=have
    message="$DETAIL_APP: $(echo $PASSED_MESSAGE | sed 's/\(.*\), \(.*\)/\1 and \2/') $have test failures|color=red"
    echo "| image='$FAIL' imageWidth=21"
  elif [ $ALL_UP_TO_DATE == false ]
  then
    case $NUMBER_BEHIND in
      1) message="$DETAIL_APP: $UP_TO_DATE_MESSAGE is behind|color=yellow";;
      *) message="$DETAIL_APP: $(echo $UP_TO_DATE_MESSAGE | sed 's/\(.*\), \(.*\)/\1 and \2/') are behind|color=yellow";;
    esac
    echo "| image='$BEHIND' imageWidth=21"
  else
    message="$DETAIL_APP: OK | color=green"
    echo "| image='$OKAY' imageWidth=21"
  fi
else
  echo ":diamond_shape_with_a_dot_inside:"
fi
echo "---"
echo "$message"
#
# Print out the detailed output of the application
#
[ -n "$DETAIL_APP" ] && printInTechnicolor "$DETAIL_APP"

#
# Print out a simple drop-down per application
#
for app in $DROPDOWN_APPS
do
  appInfoDropdown "$app"
done
