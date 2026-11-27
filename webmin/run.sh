#!/usr/bin/with-contenv bashio

# 0. Настройка русской локали для всех интерактивных сессий (включая терминал Webmin, SSH и mc)
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
    if ! grep -q "LC_ALL=ru_RU.UTF-8" "$rc_file"; then
        cat << 'EOF' >> "$rc_file"
export LANG=ru_RU.UTF-8
export LANGUAGE=ru_RU:ru
export LC_ALL=ru_RU.UTF-8
EOF
    fi
done

# Пробрасываем токен Supervisor в SSH-сессии для работы команды ha
if [ -n "${SUPERVISOR_TOKEN:-}" ] && ! grep -q "SUPERVISOR_TOKEN" /root/.bashrc; then
    echo "export SUPERVISOR_TOKEN=${SUPERVISOR_TOKEN}" >> /root/.bashrc
fi

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

# Переносим задания Cron
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

# 4. Отключаем строгую проверку Referer
if ! grep -q "referers_none=" /etc/webmin/config; then
    echo "referers_none=1" >> /etc/webmin/config
fi

# 5. Очищаем старые настройки Ingress
sed -i '/^webprefix=/d' /etc/webmin/config
sed -i '/^webprefixnoredir=/d' /etc/webmin/config
sed -i '/^cookiepath=/d' /etc/webmin/miniserv.conf

# 6. Настройка SSL из параметров аддона
if bashio::config.true 'ssl'; then
    CERTFILE="/ssl/$(bashio::config 'certfile')"
    KEYFILE="/ssl/$(bashio::config 'keyfile')"

    sed -i 's/^ssl=.*/ssl=1/' /etc/webmin/miniserv.conf

    if [ -f "${CERTFILE}" ] && [ -f "${KEYFILE}" ]; then
        bashio::log.info "Подключение пользовательских SSL-сертификатов из /ssl..."
        sed -i '/^keyfile=/d' /etc/webmin/miniserv.conf
        sed -i '/^certfile=/d' /etc/webmin/miniserv.conf
        echo "keyfile=${KEYFILE}" >> /etc/webmin/miniserv.conf
        echo "certfile=${CERTFILE}" >> /etc/webmin/miniserv.conf
    else
        bashio::log.warning "Файлы ${CERTFILE} или ${KEYFILE} не найдены. Используется встроенный сертификат Webmin."
    fi
else
    bashio::log.info "SSL отключен. Webmin работает по HTTP."
    sed -i 's/^ssl=.*/ssl=0/' /etc/webmin/miniserv.conf
fi

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
