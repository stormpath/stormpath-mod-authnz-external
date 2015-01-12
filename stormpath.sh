#!/bin/bash

echoerr() { echo "$@" 1>&2; }

[ -z "$1" ] && { echoerr "First argument must be the file path to a Stormpath apiKey.properties file"; exit 1; }
[ ! -f "$1" ] && { echoerr "First argument must be a file"; exit 1; }
[ -z "$2" ] && { echoerr "Second argument must be a Stormpath application href"; exit 2; }

appHref="$2"
#echo "Stormpath application href: $appHref"

filename="$1"
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
read -n1024 password

base64Value=$(echo -ne "$user:$password" | openssl enc -base64)

status=$(/usr/bin/curl -sw '%{http_code}' -X POST -u "$apiKeyId":"$apiKeySecret" -H 'Accept: application/json' -H 'Content-Type: application/json' -d "{\"type\": \"basic\", \"value\": \"$base64Value\"}" -o /dev/null "$appHref/loginAttempts")

if [ "$status" -ne 200 ]; then
    exit $status
fi

exit 0
