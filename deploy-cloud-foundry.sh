#!/usr/bin/env bash

TOKEN1="blue"
TOKEN2="green"
SCHEME="https"
IS_TOKEN="true"
EXPECT_STATUS="200"

if [ "$CF_HOSTNAME" == "" ]; then
  echo "ERROR: couldn't get CF_HOSTNAME. Exiting."
  exit 1
fi
if [ "$DOMAIN" == "" ]; then
  echo "ERROR: couldn't get DOMAIN. Exiting."
  exit 1
fi

do_deploy() {
  A_STATE=$(cf app "$CF_HOSTNAME-$1" --guid)
  if [ "$A_STATE" != "FAILED" ]; then
    cf unmap-route "$CF_HOSTNAME-$1" "$DOMAIN" --hostname "$CF_HOSTNAME"

    # allow time for the app to drain
    echo "Sleeping for 2 minutes to allow $CF_HOSTNAME-$1 to drain to Kinesis"
    sleep 2m
  fi
  cf push "$CF_HOSTNAME-$1" -f manifest.yml --no-start

  # do env variables
  while IFS= read -r ENV; do
    IFS=$"=" read -r -a sa <<< "$ENV"
    cf set-env "$CF_HOSTNAME-$1" "${sa[0]}" "${sa[1]}"
  done < .envs

  cf start "$CF_HOSTNAME-$1"

  SC="100"
  secs=10
  while [ $secs -gt 0 ] && [ $SC != "$EXPECT_STATUS" ]; do
    SC=$(curl -s -o /dev/null -w "%{http_code}" "$SCHEME://$CF_HOSTNAME-$1.$DOMAIN")
    echo "Checking if $CF_HOSTNAME-$1 is alive: waiting for $SC to equal $EXPECT_STATUS"
    sleep 2
    : $((secs=$((secs - 2))))
  done

  if [ "$SC" != "$EXPECT_STATUS" ]; then
    echo "ERROR: Failed to deploy $CF_HOSTNAME-$1"
    exit 1
  fi

  cf map-route "$CF_HOSTNAME-$1" "$DOMAIN" --hostname "$CF_HOSTNAME"
}

do_deploy $TOKEN1
do_deploy $TOKEN2

# deploy the user provided service

UUP_URL=""

TOKEN=""
U=""
P=""
while IFS= read -r ENV; do
  IFS=$"=" read -r -a sa <<< "$ENV"
  if [ "${sa[0]}" == "HTTP_USER" ]; then
    U="${sa[1]}"
  fi
  if [ "${sa[0]}" == "HTTP_PASSWORD" ]; then
    P="${sa[1]}"
  fi
  if [ "${sa[0]}" == "TOKEN" ]; then
    TOKEN="${sa[1]}"
  fi
done < .envs

if [ "$IS_TOKEN" == "true" ]; then
  if [ "$TOKEN" == "" ]; then
    echo "ERROR: couldn't get HTTP_USER. Exiting."
    exit 1
  fi

  UUP_URL="$SCHEME://$CF_HOSTNAME.$DOMAIN/$TOKEN"
else
  if [ "$U" == "" ]; then
    echo "ERROR: couldn't get HTTP_USER. Exiting."
    exit 1
  fi

  if [ "$P" == "" ]; then
    echo "ERROR: couldn't get HTTP_PASSWORD. Exiting."
    exit 1
  fi

  UUP_URL="$SCHEME://$U:$P@$CF_HOSTNAME.$DOMAIN"
fi

echo "Creating/updating the user provided service:"
CUPS_STATE=$(cf service "$CF_HOSTNAME" --guid)
if [ "$CUPS_STATE" == "FAILED" ]; then
  echo "Existing service '$CF_HOSTNAME' not found."
  echo "Creating for: $UUP_URL"
  if cf cups "$CF_HOSTNAME" -l "$UUP_URL"; then
    echo "Created the user provided service."
  else
    echo "ERROR: Failed to create the user provided service."
  fi
else
  echo "Existing service '$CF_HOSTNAME' found."
  echo "Updating for: $UUP_URL"
  if cf uups "$CF_HOSTNAME" -l "$UUP_URL"; then
    echo "Updated the user provided service."
  else
    echo "ERROR: Failed to update the user provided service."
  fi
fi
