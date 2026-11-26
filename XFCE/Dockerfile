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
        bindfs && \
    locale-gen ru_RU.UTF-8 && \
    update-locale LANG=ru_RU.UTF-8 LC_ALL=ru_RU.UTF-8 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    rm -f /etc/s6-overlay/s6-rc.d/user/contents.d/svc-docker \
          /etc/s6-overlay/s6-rc.d/user2/contents.d/svc-docker

RUN mkdir -p /custom-cont-init.d && \
    printf '#!/bin/bash\n\
echo "=== Configuring HA Options & Disk Access ==="\n\
if [ -f /data/options.json ]; then\n\
  for s in $(jq -r "to_entries|map(\"\(.key)=\(.value|tostring)\")|.[]" /data/options.json); do\n\
    export "$s"\n\
    echo -n "${s#*=}" > "/var/run/s6/container_environment/${s%%=*}"\n\
  done\n\
fi\n\
chmod 666 /dev/dri/* 2>/dev/null || true\n\
rm -rf /config/.cache/sessions/* /tmp/.X*-lock 2>/dev/null || true\n\
\n\
mkdir -p /mnt/disks\n\
for dir in /media/*; do\n\
  if [ -d "$dir" ]; then\n\
    name=$(basename "$dir")\n\
    mkdir -p "/mnt/disks/$name"\n\
    bindfs -u 1000 -g 1000 --perms=0775 "$dir" "/mnt/disks/$name" 2>/dev/null || true\n\
  fi\n\
done\n\
chown -R 1000:1000 /mnt/disks 2>/dev/null || true\n' > /custom-cont-init.d/00-ha-options && \
    chmod +x /custom-cont-init.d/00-ha-options
