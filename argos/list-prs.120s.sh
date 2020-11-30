#!/usr/bin/env bash

. ~/.bash_profile
export PATH=/usr/local/bin:$PATH

WORK=$TMPDIR/list-va-repos.work
REPO_CACHE=$TMPDIR/list-va-repos.cache
USED_CACHE=

[ -f "$WORK" ] && rm "$WORK"

#onExit() { rm $WORK; }
#trap onExit EXIT

#cat > $WORK <<EOF
#Y,Y,405,2019-12-05T14:07:27Z,bschofield-va,https://github.com/department-of-veterans-affairs/health-apis-data-query/pull/405,totally delete me and not approve
#EOF

pickColor() {
  local built=$1
  local approved=$2
  # FireBrick #B22222
  [ "$built" != "Y" ] && echo "color=#B22222" && return
  [ "$approved" == "A" ] && echo "color=green" && return
  # SteelBlue
  [ "$approved" == "Y" ] && echo "color=#4682b4" && return
}


prettyDate() {
  local iso8601=$1
  awk -v date="$(date +%s -d "$1")" -v now="$(date +%s)" '
    BEGIN {  diff = now - date;
       if (diff > (24*60*60)) printf "%.0f days", diff/(24*60*60);
       else if (diff > (60*60)) printf "%.0f hours", diff/(60*60);
       else if (diff > 60) printf "%.0f minutes", diff/60;
       else printf "%s seconds", diff;
    }'
}


buildRepoCache() {
  #
  # Finding repos is slow and expensive, we'll only look at GitHub every 30 minutes.
  #
  if [ -f $REPO_CACHE -a $(cat $REPO_CACHE | wc -c) -gt 0 ]
  then
    local age=$(stat -c %Y $REPO_CACHE)
    local now=$(date +%s)
    if (( $now - $age < 1800 ))
    then
      USED_CACHE="repository list was created $(prettyDate @$(stat -c %Y $REPO_CACHE))"
      return
    fi
  fi
  $DEVOPS/github/list-va-repos -o lighthouse-shanktopus > $REPO_CACHE
  USED_CACHE="Repository list was just created"
}


DEVOPS=$(find ~/va -type d -name health-apis-devops | head -1)
[ -z "$DEVOPS" ] && echo "health-apis-devops not found" && exit 1

buildRepoCache
cat $REPO_CACHE | xargs -I % $DEVOPS/github/list-pull-requests -p % > $WORK
COUNT=$(cat $WORK | wc -l)

#[ "$COUNT" == 0 ] && exit 0

printf "Pull-Requests: $COUNT"

case "$COUNT" in
  [01234]) echo "";;
  *) echo "|color=red";;
esac

echo ---
IFS="\n" cat $WORK | sort -k 3n -t , | while read line
do
  IFS=, parts=( $line )
  title=$(echo "$line" | sed 's|^.*/pull/[0-9][^,]*,||')
  built=${parts[0]}
  approved=${parts[1]}
  number=${parts[2]}
  updated=$(prettyDate ${parts[3]})
  creator=${parts[4]}
  url=${parts[5]}
  color=$(pickColor $built $approved)
  repo=$(echo -n "$url" | sed -e 's|.*/\(health-apis-\)\?\([-a-z]\+\)/pull/.*|\2|' -e 's/lighthouse-\(.*\)/\1/' -e 's/deployment/du/')
  printf "%-25s %s (%s)|href=%s trim=false font=monospace $color\n" \
    "$repo" "$title" "$updated" "$url"
done

echo -n "$USED_CACHE"
