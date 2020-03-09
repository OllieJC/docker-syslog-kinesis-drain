#!/usr/bin/env bash

set -m

# merge the environment variables with the template to configure agent.json
spruce merge /app/agent-template.json | spruce json - > /app/agent.json
cp /app/agent.json /etc/aws-kinesis/agent.json

# start the aws-kinesis-agent daemon
/etc/rc.d/init.d/aws-kinesis-agent start
# logs in: /var/log/aws-kinesis-agent/aws-kinesis-agent.log

# start up the cron daemon
/usr/sbin/crond

# start rsyslogd as a non-forked process so tini manages
/usr/share/logstash/bin/logstash -f /app/logstash.conf
