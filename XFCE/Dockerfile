ARG BUILD_FROM
ARG BUILD_VERSION
FROM ${BUILD_FROM}

ENV S6_CMD_WAIT_FOR_SERVICES=1 \
    S6_CMD_WAIT_FOR_SERVICES_MAXTIME=0 \
    S6_SERVICES_GRACETIME=0 \
    LC_ALL=ru_RU.UTF-8 \
    LANG=ru_RU.UTF-8 \
    LANGUAGE=ru_RU:ru

USER root

VOLUME [ "/sys/fs/cgroup" ]

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN \
    usermod --home /config/data_xfce abc && \
    if [[ -d /etc/services.d ]] && ls /etc/services.d/*/run 1> /dev/null 2>&1; then sed -i "1a set +e" /etc/services.d/*/run; fi

COPY ha_lsio.sh /ha_lsio.sh
ARG CONFIGLOCATION="/config/data_xfce"
RUN chmod 744 /ha_lsio.sh && if grep -qr "lsio" /etc; then /ha_lsio.sh "$CONFIGLOCATION"; fi && rm /ha_lsio.sh

COPY rootfs/ /
RUN find . -type f \( -name "*.sh" -o -name "run" -o -name "finish" \) -print -exec chmod +x {} \;

RUN if [ ! -f /bin/sh ] && [ -f /usr/bin/sh ]; then ln -s /usr/bin/sh /bin/sh; fi && \
    if [ ! -f /bin/bash ] && [ -f /usr/bin/bash ]; then ln -s /usr/bin/bash /bin/bash; fi

ARG MODULES="00-banner.sh 01-custom_script.sh 00-local_mounts.sh 00-smb_mounts.sh 90-dns_set.sh"

COPY ha_automodules.sh /ha_automodules.sh
RUN chmod 744 /ha_automodules.sh && /ha_automodules.sh "$MODULES" && rm /ha_automodules.sh

ENV PACKAGES="nginx engrampa locales language-pack-ru fonts-dejavu fonts-liberation"

COPY ha_autoapps.sh /ha_autoapps.sh
RUN chmod 744 /ha_autoapps.sh && /ha_autoapps.sh "$PACKAGES" && rm /ha_autoapps.sh

# Генерация русской локали и отключение лишнего svc-docker
RUN if command -v locale-gen >/dev/null 2>&1; then \
      locale-gen ru_RU.UTF-8 && \
      update-locale LANG=ru_RU.UTF-8 LC_ALL=ru_RU.UTF-8; \
    fi && \
    rm -f /etc/s6-overlay/s6-rc.d/user/contents.d/svc-docker \
          /etc/s6-overlay/s6-rc.d/user2/contents.d/svc-docker

COPY ha_entrypoint.sh /ha_entrypoint.sh
RUN chmod 777 /ha_entrypoint.sh

COPY bashio-standalone.sh /usr/local/lib/bashio-standalone.sh
RUN chmod 0755 /usr/local/lib/bashio-standalone.sh

ENTRYPOINT [ "/usr/bin/env" ]
CMD [ "/ha_entrypoint.sh" ]

ARG BUILD_ARCH
ARG BUILD_DATE
ARG BUILD_DESCRIPTION
ARG BUILD_NAME
ARG BUILD_REF
ARG BUILD_REPOSITORY
ARG BUILD_VERSION
ENV BUILD_VERSION="${BUILD_VERSION}"
LABEL \
    io.hass.name="${BUILD_NAME}" \
    io.hass.description="${BUILD_DESCRIPTION}" \
    io.hass.arch="${BUILD_ARCH}" \
    io.hass.type="addon" \
    io.hass.version=${BUILD_VERSION}
