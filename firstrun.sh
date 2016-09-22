#!/bin/bash

export HOME="/root"

if [[ $(cat /etc/timezone) != $TZ ]] ; then
  echo "Setting the correct time"
  echo "$TZ" > /etc/timezone
  dpkg-reconfigure -f noninteractive tzdata
  sed -i -e "s#;date.timezone.*#date.timezone = ${TZ}#g" /etc/php5/fpm/php.ini
  sed -i -e "s#;date.timezone.*#date.timezone = ${TZ}#g" /etc/php5/cli/php.ini
fi

mkdir -p /config/nginx/site-confs /config/www /config/log/nginx /config/log/letsencrypt /config/etc/letsencrypt

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

if [ ! -f "/config/nginx/jail.local" ]; then
  echo "Copying the default jail.local"
  cp /defaults/jail.local /config/nginx/jail.local
else
  echo "Using existing jail.local"
fi

if [ ! -d "/config/nginx/fail2ban-filters" ]; then
  echo "Copying default fail2ban filters"
  cp -R /defaults/fail2ban-filters /config/nginx/
else
  echo "Using existing fail2ban filters"
fi

cp /config/nginx/nginx-fpm.conf /etc/php5/fpm/pool.d/www.conf
cp /config/nginx/jail.local /etc/fail2ban/jail.local
cp /config/nginx/fail2ban-filters/* /etc/fail2ban/filter.d/
rm -f /etc/nginx/nginx.conf
ln -s /config/nginx/nginx.conf /etc/nginx/nginx.conf

rm -rf /etc/letsencrypt
ln -s /config/etc/letsencrypt /etc/letsencrypt
rm -rf /config/keys
if [ "$ONLY_SUBDOMAINS" = "true" ]; then
  DOMAIN="$(echo $SUBDOMAINS | tr ',' ' ' | awk '{print $1}')"."$URL"
  ln -s /config/etc/letsencrypt/live/"$DOMAIN" /config/keys
else
  ln -s /config/etc/letsencrypt/live/"$URL" /config/keys
fi

if [ ! -f "/config/donoteditthisfile.conf" ]; then
  echo -e "ORIGURL=\"$URL\" ORIGSUBDOMAINS=\"$SUBDOMAINS\" ORIGONLY_SUBDOMAINS=\"$ONLY_SUBDOMAINS\" ORIGDHLEVEL=\"$DHLEVEL\"" > /config/donoteditthisfile.conf
fi

if [ ! -z $SUBDOMAINS ]; then
  echo "SUBDOMAINS entered, processing"
  for job in $(echo $SUBDOMAINS | tr "," " "); do
    export SUBDOMAINS2="$SUBDOMAINS2 -d "$job"."$URL""
  done
  if [ "$ONLY_SUBDOMAINS" = true ]; then
    URLS="$SUBDOMAINS2"
    echo "Only subdomains, no URL in cert"
  else
    URLS="-d $URL $SUBDOMAINS2"
  fi
  echo "Sub-domains processed are:" $SUBDOMAINS2
else
  echo "No subdomains defined"
  URLS="-d $URL"
fi

. /config/donoteditthisfile.conf
if [ -z $ORIGONLY_SUBDOMAINS ]; then
  export ORIGONLY_SUBDOMAINS="false"
fi
if [ -z $ORIGDHLEVEL ]; then
  export ORIGDHLEVEL=$DHLEVEL
fi
echo -e "ORIGURL=\"$ORIGURL\" ORIGSUBDOMAINS=\"$ORIGSUBDOMAINS\" ORIGONLY_SUBDOMAINS=\"$ORIGONLY_SUBDOMAINS\" ORIGDHLEVEL=\"$ORIGDHLEVEL\"" > /config/donoteditthisfile.conf
if [ ! $URL = $ORIGURL ] || [ ! $SUBDOMAINS = $ORIGSUBDOMAINS ] || [ ! $ONLY_SUBDOMAINS = $ORIGONLY_SUBDOMAINS ]; then
  echo "Different sub/domains entered than what was used before. Revoking and deleting existing certificate, and an updated one will be created"
  if [ "$ORIGONLY_SUBDOMAINS" = "true" ]; then
    ORIGDOMAIN="$(echo $ORIGSUBDOMAINS | tr ',' ' ' | awk '{print $1}')"."$ORIGURL"
    /defaults/certbot-auto revoke --non-interactive --cert-path /config/etc/letsencrypt/live/"$ORIGDOMAIN"/fullchain.pem
  else
    /defaults/certbot-auto revoke --non-interactive --cert-path /config/etc/letsencrypt/live/"$ORIGURL"/fullchain.pem
  fi
  rm -rf /config/etc
  mkdir -p /config/etc/letsencrypt
  echo -e "ORIGURL=\"$URL\" ORIGSUBDOMAINS=\"$SUBDOMAINS\" ORIGONLY_SUBDOMAINS=\"$ONLY_SUBDOMAINS\" ORIGDHLEVEL=\"$DHLEVEL\"" > /config/donoteditthisfile.conf
fi

if [ ! -f "/config/nginx/dhparams.pem" ]; then
  echo "Creating DH parameters for additional security. This may take a very long time. There will be another message once this process is completed"
  openssl dhparam -out /config/nginx/dhparams.pem "$DHLEVEL"
  echo "DH parameters successfully created - " $DHLEVEL "bits"
else
  echo $ORIGDHLEVEL "bit DH parameters present"
fi

if [ ! $DHLEVEL = $ORIGDHLEVEL ]; then
  rm -rf /config/nginx/dhparams.pem
  echo "DH parameters bit setting changed. Creating new parameters. This may take a very long time. There will be another message once this process is completed"
  openssl dhparam -out /config/nginx/dhparams.pem "$DHLEVEL"
  echo "DH parameters successfully created - " $DHLEVEL "bits"
  echo -e "ORIGURL=\"$URL\" ORIGSUBDOMAINS=\"$SUBDOMAINS\" ORIGONLY_SUBDOMAINS=\"$ONLY_SUBDOMAINS\" ORIGDHLEVEL=\"$DHLEVEL\"" > /config/donoteditthisfile.conf
fi

chown -R nobody:users /config
chmod -R go-w /config/log

if [ ! -f "/config/keys/fullchain.pem" ]; then
  echo "Generating new certificate"
  cd /defaults
  ./certbot-auto certonly --non-interactive --renew-by-default --standalone --standalone-supported-challenges tls-sni-01 --rsa-key-size 4096 --email $EMAIL --agree-tos $URLS
  cd /config/keys
  openssl pkcs12 -export -out privkey.pfx -inkey privkey.pem -in cert.pem -certfile chain.pem -passout pass:
else
  cd /defaults
  ./letsencrypt.sh
fi

service php5-fpm start
service nginx start
if [ -S "/var/run/fail2ban/fail2ban.sock" ]; then
  echo "fail2ban.sock found, deleting"
  rm /var/run/fail2ban/fail2ban.sock
fi
service fail2ban start
