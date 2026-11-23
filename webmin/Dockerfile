ARG BUILD_FROM
FROM $BUILD_FROM

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    gnupg \
    perl \
    libnet-ssleay-perl \
    openssl \
    libauthen-pam-perl \
    libpam-runtime \
    libio-pty-perl \
    unzip \
    shared-mime-info \
    ca-certificates \
    && curl -fsSL https://webmin.com | gpg --dearmor -o /usr/share/keyrings/webmin.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/webmin.gpg] https://webmin.com sarge contrib" > /etc/apt/sources.list.d/webmin.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends webmin \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY run.sh /
RUN chmod a+x /run.sh

CMD [ "/run.sh" ]

COPY run.sh /
RUN chmod a+x /run.sh

CMD [ "/run.sh" ]

