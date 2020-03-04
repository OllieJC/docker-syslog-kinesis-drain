#!/usr/bin/env bash

set -m

# merge the environment variables with the template to configure agent.json
spruce merge /app/agent-template.json | spruce json - > /app/agent.json
cp /app/agent.json /etc/aws-kinesis/agent.json

# setup logstash configuration, unfortunately spruce doesn't work here
if [ -z ${PORT+x} ]; then
  PORT=10514
fi
sed -i 's@$PORT@'"$PORT"'@' /app/logstash-template.conf
sed -i 's@$LOGSTASH_USER@'"$LOGSTASH_USER"'@' /app/logstash-template.conf
sed -i 's@$LOGSTASH_PASSWORD@'"$LOGSTASH_PASSWORD"'@' /app/logstash-template.conf
cp /app/logstash-template.conf /app/logstash.conf

# start up the cron daemon
/usr/sbin/crond

# start the aws-kinesis-agent daemon
/etc/rc.d/init.d/aws-kinesis-agent start

# start rsyslogd as a non-forked process so tini manages
/usr/share/logstash/bin/logstash -f /app/logstash.conf
