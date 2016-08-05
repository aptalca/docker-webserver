#!/bin/bash
echo "<------------------------------------------------->"
echo
echo "<------------------------------------------------->"
echo "cronjob running at "$(date)
export HOME="/root"
cd /defaults
echo "Running certbot renew"
./certbot-auto -n renew --standalone --pre-hook "service nginx stop" --post-hook "service nginx start ; cd /config/keys && openssl pkcs12 -export -out privkey.pfx -inkey privkey.pem -in cert.pem -certfile chain.pem -passout pass:"
