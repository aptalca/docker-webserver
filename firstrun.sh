#!/bin/bash

if [[ $(cat /etc/timezone) != $TZ ]] ; then
  echo "$TZ" > /etc/timezone
  dpkg-reconfigure -f noninteractive tzdata
sed -i -e "s#;date.timezone.*#date.timezone = ${TZ}#g" /etc/php5/fpm/php.ini
sed -i -e "s#;date.timezone.*#date.timezone = ${TZ}#g" /etc/php5/cli/php.ini
fi

mkdir -p /config/nginx/site-confs /config/www /config/log/nginx /config/keys

if [ ! -f "/config/nginx/nginx.conf" ]; then
cp /defaults/nginx.conf /config/nginx/nginx.conf
fi

if [ ! -f "/config/nginx/nginx-fpm.conf" ]; then
cp /defaults/nginx-fpm.conf /config/nginx/nginx-fpm.conf
fi

if [ ! -f "/config/nginx/site-confs/default" ]; then
cp /defaults/default /config/nginx/site-confs/default
fi
if [[ $(find /config/www -type f | wc -l) -eq 0 ]]; then
cp /defaults/index.html /config/www/index.html
fi
cp /config/nginx/nginx-fpm.conf /etc/php5/fpm/pool.d/www.conf

if [ ! -d "/config/letsencrypt" ]; then
cd /config
git clone https://github.com/letsencrypt/letsencrypt
cd letsencrypt
./letsencrypt-auto certonly --standalone --email "$EMAIL" --agree-tos -d "$URL"

chown -R nobody:users /config
