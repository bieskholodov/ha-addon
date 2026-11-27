ARG BUILD_FROM
FROM $BUILD_FROM

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    cron \
    perl \
    libnet-ssleay-perl \
    openssl \
    libauthen-pam-perl \
    libpam-runtime \
    libio-pty-perl \
    unzip \
    shared-mime-info \
    ca-certificates \
    iproute2 \
    net-tools \
    procps \
    nmap \
    iputils-ping \
    && H="github.com" \
    && P="webmin/webmin/releases/download/2.670/webmin_2.670_all.deb" \
    && curl -fsSL -o /tmp/webmin.deb "https://${H}/${P}" \
    && apt-get install -y --no-install-recommends /tmp/webmin.deb \
    && rm -f /tmp/webmin.deb \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY run.sh /
RUN chmod a+x /run.sh

CMD [ "/run.sh" ]
