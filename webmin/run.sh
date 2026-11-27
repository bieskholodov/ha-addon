#!/usr/bin/with-contenv bashio

# 0. Настройка русской локали и переменных Home Assistant CLI (ha) для всех сессий
export LANG=ru_RU.UTF-8
export LANGUAGE=ru_RU:ru
export LC_ALL=ru_RU.UTF-8

cat << 'EOF' > /etc/default/locale
LANG=ru_RU.UTF-8
LANGUAGE=ru_RU:ru
LC_ALL=ru_RU.UTF-8
EOF

for rc_file in /etc/profile /etc/bash.bashrc /root/.bashrc; do
    touch "$rc_file"
    sed -i '/^export SUPERVISOR_TOKEN=/d' "$rc_file"
    sed -i '/^export HASSIO_TOKEN=/d' "$rc_file"
    if ! grep -q "LC_ALL=ru_RU.UTF-8" "$rc_file"; then
        cat << 'EOF' >> "$rc_file"
export LANG=ru_RU.UTF-8
export LANGUAGE=ru_RU:ru
export LC_ALL=ru_RU.UTF-8
EOF
    fi
    if [ -n "${SUPERVISOR_TOKEN:-}" ]; then
        echo "export SUPERVISOR_TOKEN=${SUPERVISOR_TOKEN}" >> "$rc_file"
        echo "export HASSIO_TOKEN=${SUPERVISOR_TOKEN}" >> "$rc_file"
    fi
done

# 1. Папка для постоянного хранения настроек Webmin, Cron, Samba и SSH (переживает обновления)
PERSIST_DIR="/data/webmin_persist"
mkdir -p "${PERSIST_DIR}/etc_webmin"
mkdir -p "${PERSIST_DIR}/cron_tabs"
mkdir -p "${PERSIST_DIR}/etc_samba"
mkdir -p "${PERSIST_DIR}/var_lib_samba"
mkdir -p "${PERSIST_DIR}/etc_ssh"
mkdir -p "${PERSIST_DIR}/root_ssh"

# Переносим стандартные конфиги Webmin
if [ ! -f "${PERSIST_DIR}/etc_webmin/miniserv.conf" ]; then
    cp -a /etc/webmin/. "${PERSIST_DIR}/etc_webmin/"
fi
rm -rf /etc/webmin
ln -s "${PERSIST_DIR}/etc_webmin" /etc/webmin

# Переносим задания Cron и восстанавливаем строгие права
if [ -d /var/spool/cron/crontabs ] && [ ! -L /var/spool/cron/crontabs ]; then
    cp -a /var/spool/cron/crontabs/. "${PERSIST_DIR}/cron_tabs/" 2>/dev/null || true
    rm -rf /var/spool/cron/crontabs
fi
mkdir -p /var/spool/cron
ln -s "${PERSIST_DIR}/cron_tabs" /var/spool/cron/crontabs
chmod 1730 "${PERSIST_DIR}/cron_tabs"
chown root:crontab "${PERSIST_DIR}/cron_tabs"
if [ -f "${PERSIST_DIR}/cron_tabs/root" ]; then
    chown root:crontab "${PERSIST_DIR}/cron_tabs/root"
    chmod 600 "${PERSIST_DIR}/cron_tabs/root"
fi

# Переносим настройки и базу паролей Samba
if [ ! -f "${PERSIST_DIR}/etc_samba/smb.conf" ] && [ -d /etc/samba ]; then
    cp -a /etc/samba/. "${PERSIST_DIR}/etc_samba/"
fi
rm -rf /etc/samba
ln -s "${PERSIST_DIR}/etc_samba" /etc/samba

if [ -d /var/lib/samba ] && [ ! -L /var/lib/samba ]; then
    if [ -z "$(ls -A "${PERSIST_DIR}/var_lib_samba")" ]; then
        cp -a /var/lib/samba/. "${PERSIST_DIR}/var_lib_samba/"
    fi
    rm -rf /var/lib/samba
fi
ln -s "${PERSIST_DIR}/var_lib_samba" /var/lib/samba
mkdir -p /var/log/samba /run/samba

# Переносим ключи хоста SSH и authorized_keys
if [ ! -f "${PERSIST_DIR}/etc_ssh/sshd_config" ] && [ -d /etc/ssh ]; then
    cp -a /etc/ssh/. "${PERSIST_DIR}/etc_ssh/"
fi
rm -rf /etc/ssh
ln -s "${PERSIST_DIR}/etc_ssh" /etc/ssh
ssh-keygen -A >/dev/null 2>&1 || true

rm -rf /root/.ssh
ln -s "${PERSIST_DIR}/root_ssh" /root/.ssh
chmod 700 "${PERSIST_DIR}/root_ssh"
mkdir -p /run/sshd

# Разрешаем вход по паролю для root в SSH
sed -i 's/^#*PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
if ! grep -q "^PermitRootLogin" /etc/ssh/sshd_config; then
    echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
fi

# 2. Установка пароля root для системы, SSH и Samba из конфигурации аддона
PASSWORD=$(bashio::config 'password')
echo "root:${PASSWORD}" | chpasswd
printf "%s\n%s\n" "${PASSWORD}" "${PASSWORD}" | smbpasswd -a -s root >/dev/null 2>&1 || true

# 3. Запрещаем Webmin уходить в фон
if ! grep -q "nofork=" /etc/webmin/miniserv.conf; then
    echo "nofork=1" >> /etc/webmin/miniserv.conf
fi

# 4. Отключаем строгую проверку Referer и настраиваем работу внутри iframe по HTTPS (Ingress)
sed -i '/^referers_none=/d' /etc/webmin/config
echo "referers_none=1" >> /etc/webmin/config
sed -i '/^relative_redir=/d' /etc/webmin/config
echo "relative_redir=1" >> /etc/webmin/config

sed -i '/^xframe_options=/d' /etc/webmin/miniserv.conf
echo "xframe_options=0" >> /etc/webmin/miniserv.conf
sed -i '/^trust_real_ip=/d' /etc/webmin/miniserv.conf
echo "trust_real_ip=1" >> /etc/webmin/miniserv.conf
sed -i '/^cookie_same_site=/d' /etc/webmin/miniserv.conf
echo "cookie_same_site=None" >> /etc/webmin/miniserv.conf

# 5. Настройка Ingress для открытия внутри боковой панели Home Assistant
INGRESS_PATH=$(bashio::addon.ingress_entry)
sed -i '/^webprefix=/d' /etc/webmin/config
sed -i '/^webprefixnoredir=/d' /etc/webmin/config
sed -i '/^cookiepath=/d' /etc/webmin/miniserv.conf

if [ -n "${INGRESS_PATH}" ]; then
    bashio::log.info "Настройка Ingress по пути: ${INGRESS_PATH}"
    echo "webprefix=${INGRESS_PATH}" >> /etc/webmin/config
    echo "webprefixnoredir=1" >> /etc/webmin/config
    echo "cookiepath=/" >> /etc/webmin/miniserv.conf
fi

# 6. Принудительно отключаем внутренний SSL Webmin для совместимости с прокси Ingress
bashio::log.info "Отключение внутреннего SSL Webmin для работы через Ingress..."
sed -i 's/^ssl=.*/ssl=0/' /etc/webmin/miniserv.conf
sed -i '/^ssl_redirect=/d' /etc/webmin/miniserv.conf
echo "ssl_redirect=0" >> /etc/webmin/miniserv.conf

# 7. Запуск фоновых служб Cron, Samba и SSH
bashio::log.info "Запуск службы Cron..."
service cron start

bashio::log.info "Запуск служб Samba (smbd, nmbd)..."
service smbd start || smbd -D
service nmbd start || nmbd -D

bashio::log.info "Запуск SSH-сервера..."
service ssh start || /usr/sbin/sshd

# 8. Запуск Webmin
bashio::log.info "Запуск Webmin..."
exec /usr/share/webmin/miniserv.pl /etc/webmin/miniserv.conf
