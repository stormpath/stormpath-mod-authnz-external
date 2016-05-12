#!/bin/bash

echoerr() { echo "$@" 1>&2; }

[ -z "$1" ] && { echoerr "First argument must be the file path to a Stormpath apiKey.properties file"; exit 1; }
[ ! -f "$1" ] && { echoerr "First argument must be a file"; exit 1; }

case "$2" in
  "username" | "email")
    ;;
  *)
    echoerr "Second argument must be either 'username' or 'email'";
    exit 2;
esac

filename="$1"
userfield="$2"
matchtype="$3"
apiKeyId=""
apiKeySecret=""

case "$matchtype" in
  "any" | "all")
    ;;
  "")
    matchtype="all"
    ;;
  *)
    echoerr "Third argument, if present, must be either 'any' or 'all' (default)";
    exit 2;
esac


IFS=$'\n'; GLOBIGNORE='*' :; LINES=($(cat $1))
for i in "${LINES[@]}"; do
  IFS='='; read -ra line <<< "$i"
  len=${#line[@]}
  for (( j=0; j < len; j++ )); do
    trimmed=$(echo "${line[$j]}" | sed -e 's/^ *//' -e 's/ *$//')
    #echo "trimmed: $trimmed"
    line[$j]=$trimmed
    #echo "line[$j] = ${line[$j]}"
    if [ "$j" -eq 1 ]; then
      if [ "${line[0]}" = "apiKey.id" ]; then
          apiKeyId="${line[1]}"
      fi
      if [ "${line[0]}" = "apiKey.secret" ]; then
          apiKeySecret="${line[1]}"
      fi
    fi
  done
done

[ -z "$apiKeyId" ] && { echoerr "File $1 does not contain a apiKey.id = id_value_value line"; exit 1; }
[ -z "$apiKeySecret" ] && { echoerr "File $1 does not contain a apiKey.secret = secret_value_here line"; exit 1; }

read -n1024 user
IFS=' ' read -n8192 -a groups

matches=""

for groupHref in "${groups[@]}"; do
  resp=$(/usr/bin/curl -s -u "$apiKeyId":"$apiKeySecret" -H 'Accept: application/json' -H 'Content-Type: application/json' -G --data-urlencode "$userfield=$user" "$groupHref/accounts"  | jq '.size')
  match=1
  if [ -z "$resp" -o "$resp" == "null" ]; then
    match=0
  fi
  if [ $resp -ne 1 ]; then
    match=0
  fi
  if [ $match -eq 0 ]; then
    if [ "$matchtype" == "all" ]; then
      echoerr "User ${user} is not in required group ${groupHref}, denying access"
      exit 1
    fi
    continue
  else
    if [ "$matchtype" == "any" ]; then
      echoerr "User ${user} is in group ${groupHref}, allowing access"
      exit 0
    fi
    matches="${matches}${groupHref}"
  fi
done

if [ -z "$matches" ]; then
  echoerr "User ${user} is not a member of any groups, denying access"
  exit 1
fi

# Since matches is not empty and we're still here, we must be using "all" match type
echoerr "User ${user} is member of all required groups, allowing access"
exit 0
