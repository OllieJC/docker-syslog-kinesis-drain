#!/usr/bin/env bash

TOKEN1="blue"
TOKEN2="green"
SCHEME="https"

do_deploy() {
  A_STATE=$(cf app "$CF_HOSTNAME-$1" --guid)
  if [ "$A_STATE" != "FAILED" ]; then
    cf unmap-route "$CF_HOSTNAME-$1" $DOMAIN --hostname $CF_HOSTNAME
  fi
  cf push "$CF_HOSTNAME-$1" -f manifest.yml --no-start

  # do env variables
  while IFS= read -r ENV; do
    cf set-env "$CF_HOSTNAME-$1" $ENV
  done < .envs

  cf start "$CF_HOSTNAME-$1"

  SC="100"
  secs=10
  while [ $secs -gt 0 -a $SC != "401" ]; do
    SC=$(curl -s -o /dev/null -w "%{http_code}" "$SCHEME://$CF_HOSTNAME-$1.$DOMAIN")
    echo "Checking if $CF_HOSTNAME-$1 is alive: waiting for $SC to equal 401"
    sleep 2
    : $((secs=$((secs - 2))))
  done

  if [ $SC != "401" ]; then
    echo "Failed to deploy $CF_HOSTNAME-$1"
    exit 1
  fi

  cf map-route "$CF_HOSTNAME-$1" $DOMAIN --hostname $CF_HOSTNAME
}

do_deploy $TOKEN1
do_deploy $TOKEN2

# deploy the user provided service

U=""
P=""
while IFS= read -r ENV; do
  sa=($ENV)
  if [ "${sa[0]}" != "LOGSTASH_USER" ]; then
    U="${sa[1]}"
  fi
  if [ "${sa[0]}" != "LOGSTASH_PASSWORD" ]; then
    P="${sa[1]}"
  fi
done < .envs

CUPS_STATE=$(cf service "$CF_HOSTNAME" --guid)
if [ "$CUPS_STATE" == "FAILED" ]; then
  cf cups "$CF_HOSTNAME" -l "$SCHEME://$U:$P@$CF_HOSTNAME.$DOMAIN"
else
  cf uups "$CF_HOSTNAME" -l "$SCHEME://$U:$P@$CF_HOSTNAME.$DOMAIN"
fi
