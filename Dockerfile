FROM fluent/fluentd:latest

ENV BUILD_DEPS="sudo build-base ruby-dev gettext"  \
    RUNTIME_DEPS="libintl bash"

RUN apk add --no-cache --update --virtual .build-deps $BUILD_DEPS && \
    apk add --no-cache --update $RUNTIME_DEPS && \
    cp /usr/bin/envsubst /usr/local/bin/envsubst

RUN sudo gem install fluent-plugin-kinesis && \
    sudo gem sources --clear-all

RUN apk del .build-deps && \
    rm -rf /tmp/* /var/tmp/* /usr/lib/ruby/gems/*/cache/*.gem

WORKDIR /app
COPY ./fluent_template.conf /app
COPY ./fluent_startup.sh /app
RUN chmod +x /app/fluent_startup.sh

RUN mkdir /app/log && \
    chown 1000:1000 /app/log

EXPOSE 10514/tcp
EXPOSE 1514/tcp
EXPOSE 1514/udp

CMD ["/bin/sh","-c","/app/fluent_startup.sh"]
