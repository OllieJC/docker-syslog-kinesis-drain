# docker-syslog-kinesis-drain
Syslog TCP/UDP/HTTP receiver to Kinesis in Docker

## Usage

### Environment Variables

- Kinesis configuration:
  - **AWS_REGION** (like `eu-west-2`)
  - **AWS_ACCESS_KEY_ID** (must have `PutRecord` and `PutRecordBatch` rights)
  - **AWS_SECRET_ACCESS_KEY**
  - **KINESIS_STREAM** (stream name - not ARN)


- CloudWatch log output:
  - _NOT USED:_
    - if `true`, events look like CloudWatch - JSON with `"messageType":"DATA_MESSAGE"` etc.  
      if `false` (default) then logs will be shipped exactly as they're received
      - **CLOUDWATCH_LIKE**
  - these are for setting the fields that CloudWatch usually sets:
    - **CW_LOGGROUP** (defaults to `syslog`)
    - **CW_OWNER** (defaults to `syslog-kinesis-drain`)
    - **CW_LOGSTREAM** (defaults to hostname of running container)


- HTTP authentication details:
  - _NOT USED:_
    - **HTTP_USER**
    - **HTTP_PASSWORD**
      - for sending HTTP POST requests to `https://user:pass@my-logging-service.my.domain` like [Cloud Foundry User-Provided Service's support](https://docs.cloudfoundry.org/devguide/services/user-provided.html)
  - **TOKEN** (this is _required_, even if using just TCP/UDP, randomly generate using something like `openssl rand -hex 16`)
    - for sending HTTP POST requests to `https://my-logging-service.my.domain/TOKEN`


- Container listeners:
  - **PORT** (the HTTP listener, defaults to `10514`)
  - **TCP_PORT** (the TCP listener, defaults to `1514`)
  - **UDP_PORT** (the UDP listener, defaults to `1514`)

### Running in Docker

TODO: [docker-compose.yml](docker-compose.yml)

`docker run -p 10514:10514 -p 514:1514/udp -p 514:1514/tcp -d -e TOKEN=supersecurelongtoken olliejc/syslog-kinesis-drain`

### Running in Cloud Foundry

Cloud Foundry app [manifest.yml](manifest.yml) example.

Script for deployment via blue-green: [deploy-cloud-foundry.sh](deploy-cloud-foundry.sh)  
The script requires a `.envs` file created with all environment variables in, like:
```
TOKEN=supersecurelongtoken
AWS_ACCESS_KEY_ID=AKFAKUSERID
AWS_SECRET_ACCESS_KEY=GAKAUTFAKESECRET
```
Usage: do `cf login` and select the right org and space then:  
`CF_HOSTNAME=my-logging-service DOMAIN=my.domain ./deploy-cloud-foundry.sh`


## Diagram

```
                     HTTP
  TCP     UDP    (basic auth)

              |
      +-------+-------+
      |    fluentd    |
      +-------+-------+
              |
              v

             AWS

```
