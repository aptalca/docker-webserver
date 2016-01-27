#!/bin/bash
echo "cronjob running at "$(date)
if [ ! -f "/config/keys/fullchain.pem" ]; then
  echo "Generating server certificate for the first time"
  if [ ! -z $SUBDOMAINS ]; then
    for job in $(echo $SUBDOMAINS | tr "," " "); do
      export SUBDOMAINS2="$SUBDOMAINS2 -d "$job"."$URL""
    done
    /config/letsencrypt/letsencrypt-auto certonly --webroot -w /config/www/ --email $EMAIL --agree-tos -d $URL $SUBDOMAINS2
  else
    /config/letsencrypt/letsencrypt-auto certonly --webroot -w /config/www/ --email $EMAIL --agree-tos -d $URL
  fi
  chown -R nobody:users /config
else
  EXP=$(date -d "`openssl x509 -in /config/keys/fullchain.pem -text -noout|grep "Not After"|cut -c 25-`" +%s)
  DATENOW=$(date -d "now" +%s)
  DAYS_EXP=$(( ( $EXP - $DATENOW ) / 86400 ))
  if [[ $DAYS_EXP -lt 30 ]]; then
    echo "Renewing certificate that is older than 60 days"
    if [ ! -z $SUBDOMAINS ]; then
      for job in $(echo $SUBDOMAINS | tr "," " "); do
        export SUBDOMAINS2="$SUBDOMAINS2 -d "$job"."$URL""
      done
      /config/letsencrypt/letsencrypt-auto certonly --renew-by-default --webroot -w /config/www/ --email $EMAIL --agree-tos -d $URL $SUBDOMAINS2
    else
      /config/letsencrypt/letsencrypt-auto certonly --renew-by-default --webroot -w /config/www/ --email $EMAIL --agree-tos -d $URL
    fi
    chown -R nobody:users /config
  else
    echo "Existing certificate is still valid for another $DAYS_EXP day(s); skipping renewal."
  fi
fi
service nginx reload
