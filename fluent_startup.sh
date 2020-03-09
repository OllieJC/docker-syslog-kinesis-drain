#!/bin/sh

echo 'Configuring fluentd...'

if [ -z ${TOKEN+x} ]; then
  echo "ERROR: TOKEN isn't set. Exiting."
  exit 1
fi

# configure defaults and replace values from template
KINESIS_STREAM_DEBUG="${KINESIS_STREAM_DEBUG:-false}" \
LOG_LEVEL="${LOG_LEVEL:-info}" \
PORT="${PORT:-10514}" \
TCP_PORT="${TCP_PORT:-1514}" \
UDP_PORT="${UDP_PORT:-1514}" \
AWS_REGION="${AWS_REGION:-us-east-1}" \
envsubst < /app/fluent_template.conf > /fluentd/etc/fluent.conf

echo 'Starting fluentd...'

fluentd --no-supervisor \
  -c /fluentd/etc/fluent.conf \
  -p /fluentd/plugins \
  $FLUENTD_OPT
