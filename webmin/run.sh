#!/usr/bin/with-contenv bashio

PASSWORD=$(bashio::config 'password')
echo "root:${PASSWORD}" | chpasswd

# Запрещаем Webmin уходить в фон, чтобы Docker-контейнер не выключался
if ! grep -q "nofork=" /etc/webmin/miniserv.conf; then
    echo "nofork=1" >> /etc/webmin/miniserv.conf
fi

# Отключаем строгую проверку Referer для доступа по IP и домену
if ! grep -q "referers_none=" /etc/webmin/config; then
    echo "referers_none=1" >> /etc/webmin/config
fi

bashio::log.info "Запуск Webmin..."
exec /usr/share/webmin/miniserv.pl /etc/webmin/miniserv.conf
