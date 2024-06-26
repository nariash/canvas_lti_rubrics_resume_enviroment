#!/bin/bash

echo "Run init.sh"
# Set apache config
echo "
ServerName $APP_DOMAIN
<VirtualHost *:80>
    ServerName $APP_DOMAIN
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/html/public
</VirtualHost>
<Directory /var/www/html>
    Options Indexes FollowSymLinks
    AllowOverride All
    Require all granted
</Directory>
" > /etc/apache2/sites-available/000-default.conf;

# Set laravel .env 
echo "
FRONTEND_ENTRYPOINT_URL=https://$FRONTEND_DOMAIN/$FRONTEND_ENTRYPOINT_URI
APP_NAME=$LARAVEL_APP_NAME
APP_ENV=$LARAVEL_APP_ENV
APP_KEY=$LARAVEL_APP_KEY
APP_DEBUG=$LARAVEL_APP_DEBUG
APP_TIMEZONE=$LARAVEL_APP_TIMEZONE
APP_URL=$LARAVEL_APP_URL

APP_LOCALE=$LARAVEL_APP_LOCALE
APP_FALLBACK_LOCALE=$LARAVEL_APP_FALLBACK_LOCALE
APP_FAKER_LOCALE=$LARAVEL_APP_FAKER_LOCALE

APP_MAINTENANCE_DRIVER=$LARAVEL_APP_MAINTENANCE_DRIVER
APP_MAINTENANCE_STORE=$LARAVEL_APP_MAINTENANCE_STORE

BCRYPT_ROUNDS=$LARAVEL_BCRYPT_ROUNDS

LOG_CHANNEL=$LARAVEL_LOG_CHANNEL
LOG_STACK=$LARAVEL_LOG_STACK
LOG_DEPRECATIONS_CHANNEL=$LARAVEL_LOG_DEPRECATIONS_CHANNEL
LOG_LEVEL=$LARAVEL_LOG_LEVEL

DB_CONNECTION=$LARAVEL_DB_CONNECTION
DB_HOST=$LARAVEL_DB_HOST
DB_PORT=$LARAVEL_DB_PORT
DB_DATABASE=$LARAVEL_DB_DATABASE
DB_USERNAME=$LARAVEL_DB_USERNAME
DB_PASSWORD=$LARAVEL_DB_PASSWORD

SESSION_DRIVER=$LARAVEL_SESSION_DRIVER
SESSION_LIFETIME=$LARAVEL_SESSION_LIFETIME
SESSION_ENCRYPT=$LARAVEL_SESSION_ENCRYPT
SESSION_PATH=$LARAVEL_SESSION_PATH
SESSION_DOMAIN=$LARAVEL_SESSION_DOMAIN

BROADCAST_CONNECTION=$LARAVEL_BROADCAST_CONNECTION
FILESYSTEM_DISK=$LARAVEL_FILESYSTEM_DISK
QUEUE_CONNECTION=$LARAVEL_QUEUE_CONNECTION

CACHE_STORE=$LARAVEL_CACHE_STORE
CACHE_PREFIX=$LARAVEL_CACHE_PREFIX

MEMCACHED_HOST=$LARAVEL_MEMCACHED_HOST

REDIS_CLIENT=$LARAVEL_REDIS_CLIENT
REDIS_HOST=$LARAVEL_REDIS_HOST
REDIS_PASSWORD=$LARAVEL_REDIS_PASSWORD
REDIS_PORT=$LARAVEL_REDIS_PORT

MAIL_MAILER=$LARAVEL_MAIL_MAILER
MAIL_HOST=$LARAVEL_MAIL_HOST
MAIL_PORT=$LARAVEL_MAIL_PORT
MAIL_USERNAME=$LARAVEL_MAIL_USERNAME
MAIL_PASSWORD=$LARAVEL_MAIL_PASSWORD
MAIL_ENCRYPTION=$LARAVEL_MAIL_ENCRYPTION
MAIL_FROM_ADDRESS=$LARAVEL_MAIL_FROM_ADDRESS
MAIL_FROM_NAME=$LARAVEL_MAIL_FROM_NAME

AWS_ACCESS_KEY_ID=$LARAVEL_AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY=$LARAVEL_AWS_SECRET_ACCESS_KEY
AWS_DEFAULT_REGION=$LARAVEL_AWS_DEFAULT_REGION
AWS_BUCKET=$LARAVEL_AWS_BUCKET
AWS_USE_PATH_STYLE_ENDPOINT=$LARAVEL_AWS_USE_PATH_STYLE_ENDPOINT

VITE_APP_NAME=$LARAVEL_VITE_APP_NAME

LTI1P3_ADMIN_USERNAME=$LARAVEL_LTI1P3_ADMIN_USERNAME
LTI1P3_ADMIN_PASSWORD=$LARAVEL_LTI1P3_ADMIN_PASSWORD

" >> /tmp/pre_stage_app/.env

# Move app to volume
if [ -z "$(ls -A /var/www/html)" ]; then
  cp -r /tmp/pre_stage_app/. /var/www/html
  composer install
  php artisan key:generate
fi
yes | php artisan migrate
mkdir -p /var/www/html/storage/logs && touch /var/www/html/storage/logs/laravel.log
chown -R www-data:www-data /var/www/html/storage/ && chmod -R 775 /var/www/html/storage/
chown -R www-data:www-data /var/www/html/bootstrap/cache && chmod -R 775 /var/www/html/bootstrap/cache
cd /var/www/html
php artisan schedule:work >> /var/log/schedule.out 2>&1 &
apache2-foreground
