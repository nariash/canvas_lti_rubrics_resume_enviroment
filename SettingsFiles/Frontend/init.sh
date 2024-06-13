#!/bin/bash

echo "Run init.sh"
# Set apache config
cd /tmp/pre_stage_frontend
cat /tmp/default_httpd.conf > /usr/local/apache2/conf/httpd.conf
echo "
ServerName $FRONTEND_DOMAIN:80
<Directory /usr/local/apache2/htdocs>
    Options Indexes FollowSymLinks
    AllowOverride All
    Require all granted
</Directory>
" >> /usr/local/apache2/conf/httpd.conf

# Set vue config 
echo "
VITE_API_URL=https://$APP_DOMAIN
" > /tmp/pre_stage_frontend/.env

# Compile and move to volume
npm install
if [ "$VUE_PRODUCTION_MODE" = "true" ]
then
  npm run build
  rm -rf /usr/local/apache2/htdocs/*
  cp -r /tmp/pre_stage_frontend/dist/* /usr/local/apache2/htdocs/
  cp /tmp/pre_stage_frontend/public/.htaccess /usr/local/apache2/htdocs/
  httpd-foreground
else
  if [ -z "$(ls -A /usr/local/apache2/htdocs)" ]; then
    cp -r /tmp/pre_stage_frontend/. /usr/local/apache2/htdocs/
  fi
  cd /usr/local/apache2/htdocs && npm run dev -- --host 0.0.0.0 --port 80
fi