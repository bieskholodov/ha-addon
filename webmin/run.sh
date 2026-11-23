#!/usr/bin/with-contenv bashio

# Получаем пароль из конфигурации аддона
PASSWORD=$(bashio::config 'password')

# Устанавливаем пароль для root
echo "root:${PASSWORD}" | chpasswd

# Запускаем Webmin без перехода в фон (foreground)
bashio::log.info "Запуск Webmin..."
exec /usr/share/webmin/miniserv.pl /etc/webmin/miniserv.conf

