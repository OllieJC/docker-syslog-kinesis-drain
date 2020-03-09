FROM amazonlinux

RUN rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch && \
    mkdir -p /etc/yum.repos.d && \
    printf "[logstash-7.x]\n\
name=Elastic repository for 7.x packages\n\
baseurl=https://artifacts.elastic.co/packages/7.x/yum\n\
gpgcheck=1\n\
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch\n\
enabled=1\n\
autorefresh=1\n\
type=rpm-md" > /etc/yum.repos.d/logstash.repo

RUN yum update -y && yum install -y \
    git \
    which \
    initscripts \
    cronie \
    logstash \
    logrotate \
    wget

RUN git clone https://github.com/awslabs/amazon-kinesis-agent.git
RUN cd amazon-kinesis-agent && \
    chmod +x ./setup && \
    ./setup --install

RUN /usr/share/logstash/bin/logstash-plugin list

RUN wget https://github.com/geofffranks/spruce/releases/download/v1.25.2/spruce-linux-amd64 && \
    mv spruce-linux-amd64 /usr/local/bin/spruce && \
    chmod +x /usr/local/bin/spruce

ENV TINI_VERSION v0.18.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini
ENTRYPOINT ["/tini", "--"]

COPY agent-template.json /app/
COPY entrypoint.sh /app/
COPY logrotated_remote-syslog /app/
COPY logstash.conf /app/
COPY ruby-logstash-filter.rb /app/
RUN chmod +x /app/entrypoint.sh && \
    mkdir /data && \
    echo "*/15 * * * * root /usr/sbin/logrotate -f /app/logrotated_remote-syslog > /dev/null 2>&1" > /etc/cron.d/logrotate

CMD ["/app/entrypoint.sh"]
