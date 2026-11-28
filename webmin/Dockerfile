ARG BUILD_FROM
FROM $BUILD_FROM

ARG BUILD_ARCH

RUN rm -f /etc/dpkg/dpkg.cfg.d/* \
    && printf "path-exclude=/usr/share/locale/*\npath-include=/usr/share/locale/ru*\npath-include=/usr/share/locale/en*\npath-include=/usr/share/locale/locale.alias\n" > /etc/dpkg/dpkg.cfg.d/01_locales \
    && apt-get update \
    && apt-get upgrade -y --no-install-recommends \
    && apt-get install -y --no-install-recommends \
    curl \
    jq \
    cron \
    smartmontools \
    fdisk \
    rsync \
    samba \
    openssh-server \
    docker.io \
    mc \
    mc-data \
    locales \
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
    && sed -i '/ru_RU.UTF-8/s/^# //g' /etc/locale.gen \
    && locale-gen ru_RU.UTF-8 \
    && H="github.com" \
    && P="webmin/webmin/releases/download/2.680/webmin_2.680_all.deb" \
    && curl -fsSL -o /tmp/webmin.deb "https://${H}/${P}" \
    && apt-get install -y --no-install-recommends /tmp/webmin.deb \
    && rm -f /tmp/webmin.deb \
    && CLI_PATH="home-assistant/cli/releases/latest/download/ha_${BUILD_ARCH}" \
    && curl -fsSL -o /usr/local/bin/ha "https://${H}/${CLI_PATH}" \
    && chmod a+x /usr/local/bin/ha \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

ENV LANG=ru_RU.UTF-8 \
    LANGUAGE=ru_RU:ru \
    LC_ALL=ru_RU.UTF-8

COPY run.sh /
RUN chmod a+x /run.sh

CMD [ "/run.sh" ]
