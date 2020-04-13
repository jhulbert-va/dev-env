#!/usr/bin/env bash

ICONS="$(dirname $(readlink -f $0))/icons"                                                                                                                                                                          
IN_PROGRESS="$(base64 -w 0 $ICONS/in_progress.ico)"  
COMPLETE="$(base64 -w 0 $ICONS/complete.ico)"

BUILD_INFO=$TMPDIR/jenkins-build-info.deployer
OUTPUT=$(mktemp)

onExit() { rm $OUTPUT; }

trap onExit EXIT

for i in qa uat staging production staging_lab lab; do
  curl -s -o $BUILD_INFO --user $JENKINS_USERNAME_PASSWORD https://tools.health.dev-developer.va.gov/jenkins/job/department-of-veterans-affairs/job/health-apis-deployer/job/$i/lastBuild/api/json?pretty=true
  isBuilding=$(cat $BUILD_INFO | jq -r '.building, .url' | paste -sd ' ')
  product=$(cat $BUILD_INFO | jq -r '.actions[] | select(._class == "hudson.model.ParametersAction") .parameters[] | select(.name == "PRODUCT") .value')

  printf "%s %s %s\n" "$i" "$isBuilding" "$product" >> $OUTPUT
done



[ $(grep -c 'true' $OUTPUT) -gt 0 ] && echo "| image='$IN_PROGRESS' imageWidth=21" || echo "| image='$COMPLETE' imageWidth=21"
awk -v inProgress="$IN_PROGRESS" -v complete="$COMPLETE" \
  'function printDeployment(icon, app) {
     printf("%-13s %s | image=%s imageWidth=21 font=monospace href=%s\n", $1, app, icon, $3)
   }
   BEGIN { printf "---\n"}
   { if ($2 == "true") {
       printDeployment(inProgress, $4)
     } else {
       printDeployment(complete, "")
     }
   }' $OUTPUT
