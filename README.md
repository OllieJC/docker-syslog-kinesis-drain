# docker-syslog-kinesis-drain
Syslog TCP/UDP/HTTP receiver to Kinesis in Docker

## Usage

### Environment Variables

- Kinesis configuration:
  - **AWS_ACCESS_KEY_ID** (must have `PutRecord` rights)
  - **AWS_SECRET_ACCESS_KEY**
  - **ASSUME_ROLE_ARN** (optional to tell the [amazon-kinesis-agent](https://github.com/awslabs/amazon-kinesis-agent) another role to assume)
  - **CLOUDWATCH_EMITMETRICS** (default is `false`, if `true` then `PutMetricData` rights is needed)
  - **KINESIS_ENDPOINT** (like `kinesis.eu-west-2.amazonaws.com`)
  - **FIREHOSE_ENDPOINT** (like `monitoring.eu-west-2.amazonaws.com`)
  - **KINESIS_STREAM** (stream name - not ARN)
  - **PARTITION_KEY_OPTION** (defaults to `RANDOM`, other possible value is `DETERMINISTIC` [see here](https://docs.aws.amazon.com/streams/latest/dev/writing-with-agents.html))
  - **MATCH_PATTERN** (defaults to empty string so all events, can be a regular expression of which events to send)


- CloudWatch log output:
  - if `true`, events look like CloudWatch - JSON with `"messageType":"DATA_MESSAGE"` etc.  
    if `false` (default) then logs will be shipped exactly as they're received
    - **CLOUDWATCH_LIKE**
  - these are for setting the fields that CloudWatch usually sets:
    - **CW_LOGGROUP** (defaults to `syslog`)
    - **CW_OWNER** (defaults to hostname of running container)
    - **CW_LOGSTREAM** (defaults to `host` Logstash field - typically the sender IP)


- Logstash HTTP basic authentication details:
  - **LOGSTASH_PASSWORD**
  - **LOGSTASH_USER**
  - for sending HTTP POST requests to `https://user:pass@my-logging-service.my.domain` like [Cloud Foundry User-Provided Service's support](https://docs.cloudfoundry.org/devguide/services/user-provided.html)


- Logstash listeners:
  - **PORT** (the HTTP listener, defaults to `10514`)
  - **TCP_PORT** (the TCP listener, defaults to `514`)
  - **UDP_PORT** (the UDP listener, defaults to `514`)

### Running in Docker

TODO: [docker-compose.yml](docker-compose.yml)

`docker run -p 10514:10514 -p 514:514/udp -p 514:514/tcp -d -e CLOUDWATCH_LIKE=true -e LOGSTASH_USER=tmp -e LOGSTASH_PASSWORD=supersecure olliejc/syslog-kinesis-drain`

### Running in Cloud Foundry

Cloud Foundry app [manifest.yml](manifest.yml) example.

Script for deployment via blue-green: [deploy-cloud-foundry.sh](deploy-cloud-foundry.sh)  
The script requires a `.envs` file created with all environment variables in, like:
```
AWS_ACCESS_KEY_ID AKFAKUSERID
AWS_SECRET_ACCESS_KEY GAKAUTFAKESECRET
```
Usage: do `cf login` and select the right org and space then:  
`CF_HOSTNAME=my-logging-service DOMAIN=my.domain ./deploy-cloud-foundry.sh`


## Diagram

```
                     HTTP
  TCP     UDP    (basic auth)
                                                        +---------+
              |                                         |  crond  |
      +-------+-------+                                 +----+----+
      |   Logstash    +------------+                         |
      +---------------+            |                         |
                                   v                  +- ----v------+
                        /data/remote-syslog.log   <---+  logrotate  |
                                   +                  +-------------+
   +---------------------+         |
   |  aws|kinesis|agent  +<--------+
   +----------+----------+
              |
              v

             AWS
```
