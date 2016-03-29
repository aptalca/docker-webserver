#!/bin/bash
echo "cronjob running at "$(date)
cd /defaults
. domains.conf
echo "URL is" $URL
echo "Subdomains are" $SUBDOMAINS
echo "updating letsencrypt dependencies; help info will be displayed, you can ignore that :-)"
cd /config/letsencrypt
./letsencrypt-auto --help
if [ -f "/config/keys/fullchain.pem" ]; then
  EXP=$(date -d "`openssl x509 -in /config/keys/fullchain.pem -text -noout|grep "Not After"|cut -c 25-`" +%s)
  DATENOW=$(date -d "now" +%s)
  DAYS_EXP=$(( ( $EXP - $DATENOW ) / 86400 ))
  if [[ $DAYS_EXP -gt 30 ]]; then
    echo "Existing certificate is still valid for another $DAYS_EXP day(s); skipping renewal."
    exit 0
  else
    echo "Preparing to renew certificate that is older than 60 days"
  fi
else
  echo "Preparing to generate server certificate for the first time"
fi
echo "Temporarily stopping Nginx"
service nginx stop
echo "Generating/Renewing certificate"
./letsencrypt-auto certonly --renew-by-default --standalone --standalone-supported-challenges tls-sni-01 --email $EMAIL --agree-tos -d $URL $SUBDOMAINS2
chown -R nobody:users /config
echo "Restarting web server"
service nginx start
