#!/bin/bash

docker run --rm \
    -v /var/www/certbot:/var/www/certbot:rw \
    -v /etc/nginx/ssl:/etc/letsencrypt:rw \
    certbot/certbot:latest \
    renew --agree-tos

