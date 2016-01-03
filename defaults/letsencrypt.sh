#!/bin/bash
echo "cronjob running at "$(date)
if [ ! -f "/config/keys/fullchain.pem" ]; then
  echo "Generating server certificate for the first time"
  service nginx stop
  /config/letsencrypt/letsencrypt-auto certonly --standalone --standalone-supported-challenges tls-sni-01 --email "$EMAIL" --agree-tos -d "$URL"
  chown -R nobody:users /config
else
  diff=$(( (`date +%s` - `stat -c "%Y" /config/keys/fullchain.pem`) / 86400 ))
  if [[ $diff > 60 ]]; then
    echo "Renewing certificate that is older than 60 days"
    service nginx stop
    /config/letsencrypt/letsencrypt-auto certonly --renew-by-default --standalone --standalone-supported-challenges tls-sni-01 --email "$EMAIL" --agree-tos -d "$URL" "$SUBDOMAINS2"
    chown -R nobody:users /config
  else
    echo "Existing certificate is still valid and is only $diff day(s) old; skipping renewal."
  fi
fi
service nginx start
