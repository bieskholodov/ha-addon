#!/usr/bin/with-contenv bashio

# 1. Папка для постоянного хранения настроек Webmin и Cron (переживает обновления)
PERSIST_DIR="/data/webmin_persist"
mkdir -p "${PERSIST_DIR}/etc_webmin"
mkdir -p "${PERSIST_DIR}/cron_tabs"

# Переносим стандартные конфиги Webmin в постоянную папку при самом первом запуске
if [ ! -f "${PERSIST_DIR}/etc_webmin/miniserv.conf" ]; then
    cp -a /etc/webmin/. "${PERSIST_DIR}/etc_webmin/"
fi
rm -rf /etc/webmin
ln -s "${PERSIST_DIR}/etc_webmin" /etc/webmin

# Переносим задания Cron в постоянную папку
if [ -d /var/spool/cron/crontabs ] && [ ! -L /var/spool/cron/crontabs ]; then
    cp -a /var/spool/cron/crontabs/. "${PERSIST_DIR}/cron_tabs/" 2>/dev/null || true
    rm -rf /var/spool/cron/crontabs
fi
mkdir -p /var/spool/cron
ln -s "${PERSIST_DIR}/cron_tabs" /var/spool/cron/crontabs
chmod 1730 "${PERSIST_DIR}/cron_tabs"
chown root:crontab "${PERSIST_DIR}/cron_tabs"

# 2. Установка пароля root из конфигурации аддона
PASSWORD=$(bashio::config 'password')
echo "root:${PASSWORD}" | chpasswd

# 3. Запрещаем Webmin уходить в фон
if ! grep -q "nofork=" /etc/webmin/miniserv.conf; then
    echo "nofork=1" >> /etc/webmin/miniserv.conf
fi

# 4. Отключаем строгую проверку Referer
if ! grep -q "referers_none=" /etc/webmin/config; then
    echo "referers_none=1" >> /etc/webmin/config
fi

# 5. Очищаем старые настройки Ingress, чтобы Webmin открывался от корня /
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

# 7. Запуск фоновой службы Cron
bashio::log.info "Запуск службы Cron..."
service cron start

# 8. Запуск Webmin
bashio::log.info "Запуск Webmin..."
exec /usr/share/webmin/miniserv.pl /etc/webmin/miniserv.conf
