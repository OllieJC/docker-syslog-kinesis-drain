#!/usr/bin/env bash

set -m

# merge the environment variables with the template to configure agent.json
spruce merge /app/agent-template.json | spruce json - > /app/agent.json
cp /app/agent.json /etc/aws-kinesis/agent.json

# start up the cron daemon
/usr/sbin/crond

# start the aws-kinesis-agent daemon
/etc/rc.d/init.d/aws-kinesis-agent start

# start rsyslogd as a non-forked process so tini manages
/usr/sbin/rsyslogd -n
