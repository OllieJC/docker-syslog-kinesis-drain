FROM amazonlinux

RUN yum update -y && yum install git which rsyslog initscripts cronie -y

RUN git clone https://github.com/awslabs/amazon-kinesis-agent.git
RUN cd amazon-kinesis-agent && \
    chmod +x ./setup && \
    ./setup --install

RUN wget https://github.com/geofffranks/spruce/releases/download/v1.25.2/spruce-linux-amd64 && \
    mv spruce-linux-amd64 /usr/local/bin/spruce && \
    chmod +x /usr/local/bin/spruce

COPY . /app
RUN chmod +x /app/entrypoint.sh && \
    mv /app/rsyslog.conf /etc/rsyslog.conf && \
    mkdir /data && \
    touch /data/remote-syslog.log && \
    mv /app/logrotated_remote-syslog /etc/logrotate.d/remote-syslog && \
    echo "*/15 * * * * root /usr/sbin/logrotate -f /etc/logrotate.d/remote-syslog > /dev/null 2>&1" > /etc/cron.d/logrotate

ENV TINI_VERSION v0.18.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini
ENTRYPOINT ["/tini", "--"]

CMD ["/app/entrypoint.sh"]
