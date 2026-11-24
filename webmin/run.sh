#!/usr/bin/with-contenv bashio

PASSWORD=$(bashio::config 'password')
echo "root:${PASSWORD}" | chpasswd

# Запрещаем Webmin уходить в фон
if ! grep -q "nofork=" /etc/webmin/miniserv.conf; then
    echo "nofork=1" >> /etc/webmin/miniserv.conf
fi

# Отключаем строгую проверку Referer
if ! grep -q "referers_none=" /etc/webmin/config; then
    echo "referers_none=1" >> /etc/webmin/config
fi

# Получаем динамический путь Ingress от Home Assistant
INGRESS_ENTRY=$(bashio::addon.ingress_entry)

# Настраиваем Webmin для работы по префиксу Ingress
sed -i '/^webprefix=/d' /etc/webmin/config
sed -i '/^webprefixnoredir=/d' /etc/webmin/config
echo "webprefix=${INGRESS_ENTRY}" >> /etc/webmin/config
echo "webprefixnoredir=1" >> /etc/webmin/config

# Разрешаем работу cookies по пути Ingress
sed -i '/^cookiepath=/d' /etc/webmin/miniserv.conf
echo "cookiepath=${INGRESS_ENTRY}" >> /etc/webmin/miniserv.conf

# Настройка SSL из параметров аддона
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
    bashio::log.info "SSL отключен. Webmin работает по HTTP (рекомендуется для Ingress)."
    sed -i 's/^ssl=.*/ssl=0/' /etc/webmin/miniserv.conf
fi

bashio::log.info "Запуск Webmin..."
exec /usr/share/webmin/miniserv.pl /etc/webmin/miniserv.conf
