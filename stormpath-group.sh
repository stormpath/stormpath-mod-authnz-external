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
apiKeyId=""
apiKeySecret=""

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

for groupHref in "${groups[@]}"; do
  echo "CHECKING ${user} IN ${groupHref}" >>/tmp/debug.log
  resp=$(/usr/bin/curl -u "$apiKeyId":"$apiKeySecret" -H 'Accept: application/json' -H 'Content-Type: application/json' -G --data-urlencode "$userfield=$user" "$groupHref/accounts"  | jq '.size')
  if [ -z "$resp" -o "$resp" == "null" ]; then
      exit 1
  fi
  if [ $resp -ne 1 ]; then
      exit 1
  fi
done

exit 0
