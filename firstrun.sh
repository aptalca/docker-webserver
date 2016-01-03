#!/bin/bash

if [[ $(cat /etc/timezone) != $TZ ]] ; then
  echo "Setting the correct time"
  echo "$TZ" > /etc/timezone
  dpkg-reconfigure -f noninteractive tzdata
  sed -i -e "s#;date.timezone.*#date.timezone = ${TZ}#g" /etc/php5/fpm/php.ini
  sed -i -e "s#;date.timezone.*#date.timezone = ${TZ}#g" /etc/php5/cli/php.ini
fi

mkdir -p /config/nginx/site-confs /config/www /config/log/nginx /config/etc/letsencrypt

if [ ! -f "/config/nginx/nginx.conf" ]; then
  echo "Copying the default nginx.conf"
  cp /defaults/nginx.conf /config/nginx/nginx.conf
else
  echo "Using existing nginx.conf"
fi

if [ ! -f "/config/nginx/nginx-fpm.conf" ]; then
  echo "Copying the default nginx-fpm.conf"
  cp /defaults/nginx-fpm.conf /config/nginx/nginx-fpm.conf
else
  echo "Using existing nginx-fpm.conf"
fi

if [ ! -f "/config/nginx/site-confs/default" ]; then
  echo "Copying the default site config"
  cp /defaults/default /config/nginx/site-confs/default
else
  echo "Using existing site config"
fi

if [[ $(find /config/www -type f | wc -l) -eq 0 ]]; then
  echo "Copying the default landing page"
  cp /defaults/index.html /config/www/index.html
else
  echo "Using existing landing page"
fi

cp /config/nginx/nginx-fpm.conf /etc/php5/fpm/pool.d/www.conf
rm -f /etc/nginx/nginx.conf
ln -s /config/nginx/nginx.conf /etc/nginx/nginx.conf

cd /config

if [ ! -d "/config/letsencrypt" ]; then
  echo "Setting up letsencrypt for the first time"
  git clone https://github.com/letsencrypt/letsencrypt
else
  echo "Using existing letsencrypt installation"
fi

rm -r /etc/letsencrypt
ln -s /config/etc/letsencrypt /etc/letsencrypt
rm /config/keys
ln -s /config/etc/letsencrypt/live/"$URL" /config/keys

if [ ! -z $SUBDOMAINS ]; then
  echo "SUBDOMAINS entered, processing"
  for job in $(echo $SUBDOMAINS | tr "," " "); do
    SUBDOMAINS2=" -d "$job"."$URL" $SUBDOMAINS2"
  done
  echo "Sub-domains processed are:" $SUBDOMAINS2
fi

if [ ! -f "/config/nginx/dhparams.pem" ]; then
  echo "Creating DH parameters for additional security. This may take a very long time. There will be another message once this process is completed"
  openssl dhparam -out /config/nginx/dhparams.pem 2048
  echo "DH parameters successfully created"
else
  echo "Using existing DH parameters"
fi

chown -R nobody:users /config
/defaults/letsencrypt.sh
