#!/bin/bash
echo "cronjob running at "$(date)
service nginx stop
/config/letsencrypt/letsencrypt-auto certonly --standalone --standalone-supported-challenges tls-sni-01 --email "$EMAIL" --agree-tos -d "$URL"
service nginx start
