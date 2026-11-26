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
        nano \
        jq \
        dbus-x11 \
        ntfs-3g \
        exfatprogs \
        util-linux \
        acl && \
    locale-gen ru_RU.UTF-8 && \
    update-locale LANG=ru_RU.UTF-8 LC_ALL=ru_RU.UTF-8 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    rm -f /etc/s6-overlay/s6-rc.d/user/contents.d/svc-docker \
          /etc/s6-overlay/s6-rc.d/user2/contents.d/svc-docker

RUN mkdir -p /etc/cont-init.d && \
    printf '#!/usr/bin/with-contenv bash\n\
if [ -f /data/options.json ]; then\n\
  for s in $(jq -r "to_entries|map(\"\(.key)=\(.value|tostring)\")|.[]" /data/options.json); do\n\
    export "$s"\n\
    echo -n "${s#*=}" > "/var/run/s6/container_environment/${s%%=*}"\n\
  done\n\
fi\n\
chmod 666 /dev/dri/* 2>/dev/null || true\n\
rm -rf /config/.cache/sessions/* /tmp/.X*-lock 2>/dev/null || true\n\
USER_ID=${PUID:-1000}\n\
[ "$USER_ID" -eq 0 ] && USER_ID=1000\n\
chmod 755 /media /homeassistant /share /backup /ssl 2>/dev/null || true\n\
setfacl -R -m u:${USER_ID}:rwx /media/* /homeassistant /share /backup /ssl 2>/dev/null || chmod -R a+rwX /media/* /homeassistant /share /backup /ssl 2>/dev/null || true\n' > /etc/cont-init.d/00-ha-options && \
    chmod +x /etc/cont-init.d/00-ha-options
