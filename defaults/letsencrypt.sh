#!/bin/bash

/config/letsencrypt/letsencrypt-auto certonly --standalone --standalone-supported-challenges tls-sni-01 --email \"$EMAIL\" --agree-tos -d \"$URL\"
