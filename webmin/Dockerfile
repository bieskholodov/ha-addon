ARG BUILD_FROM
FROM $BUILD_FROM

# Установка зависимостей и репозитория Webmin
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
    && curl -o setup-repos.sh https://githubusercontent.com \
    && sh setup-repos.sh -f \
    && apt-get update \
    && apt-get install -y --no-install-recommends webmin \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* setup-repos.sh

COPY run.sh /
RUN chmod a+x /run.sh

CMD [ "/run.sh" ]

