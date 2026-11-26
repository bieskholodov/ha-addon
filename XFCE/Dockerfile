ARG BUILD_FROM=lscr.io/linuxserver/webtop:ubuntu-xfce
FROM ${BUILD_FROM}

ENV DEBIAN_FRONTEND=noninteractive \
    LC_ALL=ru_RU.UTF-8 \
    LANG=ru_RU.UTF-8 \
    LANGUAGE=ru_RU:ru

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        locales \
        language-pack-ru \
        fonts-dejavu \
        fonts-liberation \
        engrampa \
        curl \
        wget \
        nano && \
    locale-gen ru_RU.UTF-8 && \
    update-locale LANG=ru_RU.UTF-8 LC_ALL=ru_RU.UTF-8 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
