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

# 2. Установка пароля root для системы, Webmin, SSH и Samba из конфигурации аддона
PASSWORD=$(bashio::config 'password')
echo "root:${PASSWORD}" | chpasswd
printf "%s\n%s\n" "${PASSWORD}" "${PASSWORD}" | smbpasswd -a -s root >/dev/null 2>&1 || true

# Восстанавливаем штатную запись root:x:0 в Webmin (именно буква x включает проверку системного root)
echo "root:x:0" > /etc/webmin/miniserv.users
chmod 600 /etc/webmin/miniserv.users
echo "root: *" > /etc/webmin/webmin.acl
chmod 600 /etc/webmin/webmin.acl

# 3. Запрещаем Webmin уходить в фон и возвращаем стандартную проверку PAM/shadow
if ! grep -q "nofork=" /etc/webmin/miniserv.conf; then
    echo "nofork=1" >> /etc/webmin/miniserv.conf
fi
sed -i '/^no_pam=/d' /etc/webmin/miniserv.conf
sed -i '/^userfile=/d' /etc/webmin/miniserv.conf
echo "userfile=/etc/webmin/miniserv.users" >> /etc/webmin/miniserv.conf

# 4. Базовые сетевые настройки Webmin
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

# Очищаем старые настройки путей, сессий, автовхода и ограничений IP перед выбором режима
sed -i '/^webprefix=/d' /etc/webmin/config
sed -i '/^webprefixnoredir=/d' /etc/webmin/config
sed -i '/^cookiepath=/d' /etc/webmin/miniserv.conf
sed -i '/^ssl_redirect=/d' /etc/webmin/miniserv.conf
sed -i '/^session=/d' /etc/webmin/miniserv.conf
sed -i '/^always_auth_user=/d' /etc/webmin/miniserv.conf
sed -i '/^anonymous=/d' /etc/webmin/miniserv.conf
sed -i '/^allow=/d' /etc/webmin/miniserv.conf

# 5. Переключение режима в зависимости от опции SSL
if bashio::config.true 'ssl'; then
    # РЕЖИМ 1: Прямой доступ по HTTPS (вход строго по паролю с формой сессии, Ingress отключен)
    bashio::log.info "Режим SSL включен: прямой вход по https://<IP>:10000/ с запросом пароля"
    CERTFILE="/ssl/$(bashio::config 'certfile')"
    KEYFILE="/ssl/$(bashio::config 'keyfile')"

    sed -i 's/^ssl=.*/ssl=1/' /etc/webmin/miniserv.conf
    echo "ssl_redirect=1" >> /etc/webmin/miniserv.conf
    echo "session=1" >> /etc/webmin/miniserv.conf
    echo "cookiepath=/" >> /etc/webmin/miniserv.conf

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
    # РЕЖИМ 2: Работа внутри боковой панели Home Assistant (Ingress + окно входа браузера)
    bashio::log.info "Режим SSL выключен: работа внутри боковой панели Home Assistant (session=0)"
    sed -i 's/^ssl=.*/ssl=0/' /etc/webmin/miniserv.conf
    echo "ssl_redirect=0" >> /etc/webmin/miniserv.conf
    echo "session=0" >> /etc/webmin/miniserv.conf
    echo "allow=172.30.32.2 127.0.0.1" >> /etc/webmin/miniserv.conf

    INGRESS_PATH=$(bashio::addon.ingress_entry)
    if [ -n "${INGRESS_PATH}" ]; then
        bashio::log.info "Путь Ingress: ${INGRESS_PATH}"
        echo "webprefix=${INGRESS_PATH}" >> /etc/webmin/config
        echo "webprefixnoredir=1" >> /etc/webmin/config
        echo "cookiepath=/" >> /etc/webmin/miniserv.conf
    fi
fi

# 6. Запуск фоновых служб Cron, Samba и SSH
bashio::log.info "Запуск службы Cron..."
service cron start

bashio::log.info "Запуск служб Samba (smbd, nmbd)..."
service smbd start || smbd -D
service nmbd start || nmbd -D

bashio::log.info "Запуск SSH-сервера..."
service ssh start || /usr/sbin/sshd

# 7. Запуск Webmin
bashio::log.info "Запуск Webmin..."
exec /usr/share/webmin/miniserv.pl /etc/webmin/miniserv.conf
