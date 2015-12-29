#!/bin/bash
echo "cronjob running at "$(date)
service nginx stop
if [ ! -f "/config/keys/fullchain.pem" ]; then
  echo "Generating server certificate for the first time"
  /config/letsencrypt/letsencrypt-auto certonly --standalone --standalone-supported-challenges tls-sni-01 --email "$EMAIL" --agree-tos -d "$URL"
else
  diff=$(( (`date +%s` - `stat -c "%Y" /config/keys/fullchain.pem`) / 86400 ))
  if [[ $diff > 60 ]]; then
    echo "Renewing certificate that is older than 60 days"
    /config/letsencrypt/letsencrypt-auto certonly --standalone --standalone-supported-challenges tls-sni-01 --email "$EMAIL" --agree-tos -d "$URL"
  else
    echo "Existing certificate is still valid, skipping renewal."
  fi
fi
chown -R nobody:users /config
service nginx start
