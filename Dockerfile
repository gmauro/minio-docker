FROM alpine:3.6

# Application settings
ENV APP_HOME="/opt/minio" \
    APP_VERSION="RELEASE.2017-10-27T18-59-02Z" \
    USER=minio \
    GROUP=minio \
    UID=11350 \
    GID=4046 

ENV PATH=$PATH:${APP_HOME}/bin


# Install extra package
RUN apk --update add fping curl bash &&\
    rm -rf /var/cache/apk/*


# Install Glibc for minio
ENV GLIBC_VERSION="2.23-r1"
RUN \
    apk add --update -t deps wget ca-certificates &&\
    cd /tmp &&\
    wget https://github.com/andyshinn/alpine-pkg-glibc/releases/download/${GLIBC_VERSION}/glibc-${GLIBC_VERSION}.apk &&\
    wget https://github.com/andyshinn/alpine-pkg-glibc/releases/download/${GLIBC_VERSION}/glibc-bin-${GLIBC_VERSION}.apk &&\
    apk add --allow-untrusted glibc-${GLIBC_VERSION}.apk glibc-bin-${GLIBC_VERSION}.apk &&\
    /usr/glibc-compat/sbin/ldconfig /lib /usr/glibc-compat/lib/ &&\
    echo 'hosts: files mdns4_minimal [NOTFOUND=return] dns mdns4' >> /etc/nsswitch.conf &&\
    apk del --purge deps &&\
    rm /tmp/* /var/cache/apk/*

# Install minio software
RUN \
    mkdir -p ${APP_HOME}/log /data ${APP_HOME}/bin ${APP_HOME}/conf && \
    curl -f https://dl.minio.io/server/minio/release/linux-amd64/archive/minio.${APP_VERSION} -o ${APP_HOME}/bin/minio && \
    addgroup -g ${GID} ${GROUP} && \
    adduser -g "${USER} user" -D -h ${APP_HOME} -G ${GROUP} -s /bin/sh -u ${UID} ${USER}

COPY dockerscripts/docker-entrypoint.sh dockerscripts/healthcheck.sh ${APP_HOME}/bin/

RUN chmod +x ${APP_HOME}/bin/* &&\
    chown -R ${USER}:${GROUP} ${APP_HOME}

USER ${USER}

EXPOSE 9000

ENTRYPOINT ["docker-entrypoint.sh"]

VOLUME ["/data"]

HEALTHCHECK --interval=30s --timeout=5s \
    CMD healthcheck.sh

CMD ["minio"]