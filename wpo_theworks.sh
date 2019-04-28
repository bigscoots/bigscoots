#!/bin/bash

exit_on_error() {
    exit_code=$1
    last_command=${@:2}
    if [ "$exit_code" -ne 0 ]; then
        >&2 echo "\"${last_command}\" command failed with exit code ${exit_code}."
        exit "$exit_code"
    fi
}

if [[ $1 == fresh ]];then

  DOMAIN=$(echo "$(pwd)"| sed "s=/home/nginx/domains/==g ; s=/public==g")

  wp --allow-root --skip-plugins --skip-themes search-replace http: https:
  /bigscoots/wpo_forcehttps.sh "$DOMAIN"
  nginx -t

else

  if hash wp 2>/dev/null; then
  echo found wp-cli

  dbname=$(wp --allow-root --skip-plugins --skip-themes config get DB_NAME)
  dbuser=$(wp --allow-root --skip-plugins --skip-themes config get DB_USER)
  dbpass=$(wp --allow-root --skip-plugins --skip-themes config get DB_PASSWORD)
  wp --allow-root --skip-plugins --skip-themes config set DB_HOST localhost
  wp --allow-root --skip-plugins --skip-themes config delete FS_METHOD
  wp --allow-root --skip-plugins --skip-themes config delete FS_CHMOD_DIR
  wp --allow-root --skip-plugins --skip-themes config delete FS_CHMOD_FILE
  sed -i '/gd-config.php/d' wp-config.php

  else

  dbname=$(grep DB_NAME wp-config.php | grep -v WP_CACHE_KEY_SALT | grep -v '^//' | cut -d \' -f 4 )
  dbuser=$(grep DB_USER wp-config.php | grep -v WP_CACHE_KEY_SALT | grep -v '^//' | cut -d \' -f 4 )
  dbpass=$(grep DB_PASSWORD wp-config.php | grep -v WP_CACHE_KEY_SALT | grep -v '^//' | cut -d \' -f 4 )
  dbhost=$(grep DB_HOST wp-config.php | grep -v WP_CACHE_KEY_SALT | grep -v '^//' | cut -d \' -f 4 | sed 's/:/ /g' | awk '{print $1}')

  fi

  echo "Database Name: $dbname"
  echo "Database User: $dbuser"
  echo "Database Password: $dbpass"
  echo "Creating database: $dbname"

  mysql -e "CREATE DATABASE $dbname;"

  echo "Assigning Database User: $dbuser to Database: $dbname using Password: $dbpass"
  /usr/bin/mysql -e "grant all privileges on $dbname.* to '$dbuser'@'localhost' identified by '$dbpass';"

wp --allow-root --skip-plugins --skip-themes db import bigscoots.sql
exit_on_error $? MySQL Import

mv bigscoots.sql ../

fi

# remove unnecessary files

rm -rfv wp-content/mu-plugins/SupportCenterMUAutoloader.php  wp-content/mu-plugins/et-safe-mode  wp-content/mu-plugins/wp-stack-cache.php wp-content/plugins/mojo-marketplace-wp-plugin wp-content/mu-plugins/force-strong-passwords wp-content/mu-plugins/mu-plugin.php wp-content/mu-plugins/slt-force-strong-passwords.php wp-content/mu-plugins/stop-long-comments.php wp-content/mu-plugins/wpengine-common wp-content/object-cache.php wp-content/mu-plugins/endurance-* wp-content/mu-plugins/liquidweb_mwp.php wp-content/mu-plugins/lw-varnish-cache-purger.php wp-content/mu-plugins/lw_disable_nags.php wp-content/mu-plugins/kinsta-mu-plugins* wp-content/cache wp-content/object-cache.php wp-content/db.php

sed -i '/^[[:blank:]]*\*/d;s/\/\*\*.*//;/^$/d' wp-config.php

# remove unnecessary files

# Caching setups, only do 1 - START

# redis
# wp plugin install nginx-helper --activate --allow-root --skip-plugins  ; wp plugin delete comet-cache sg-cachepress wp-hummingbird wp-super-cache w3-total-cache wp-redis wp-fastest-cache wp-rocket litespeed-cache --allow-root --skip-plugins --skip-themes ; chown -R nginx: .


# CACHING

if [ -d "wp-content/plugins/wp-rocket" ]; then

  if [ ! -d "/usr/local/nginx/conf/rocket-nginx" ]; then

  bringmeback=$(pwd)
  cd /usr/local/nginx/conf/ || exit
  git clone https://github.com/maximejobin/rocket-nginx.git
  cd rocket-nginx || exit
  cp rocket-nginx.ini.disabled rocket-nginx.ini
  php rocket-parser.php
  cd "$bringmeback" || exit

    for i in wpsupercache_ wpcacheenabler_ rediscache_
      do
        sed -iE "/$i/s/#\?include /#include /g" /usr/local/nginx/conf/conf.d/"$(pwd | sed 's/\// /g' | awk '{print $4}')".ssl.conf
    done
        sed -iE '/rocket-nginx\/default.conf/s/#\?include/include/g' /usr/local/nginx/conf/conf.d/"$(pwd | sed 's/\// /g' | awk '{print $4}')".ssl.conf

    if grep -q "rocket-nginx/default.conf" /usr/local/nginx/conf/conf.d/"$(pwd | sed 's/\// /g' | awk '{print $4}')".ssl.conf ; then
    for i in wpsupercache_ wpcacheenabler_ rediscache_
      do
        sed -iE "/$i/s/#\?include /#include /g" /usr/local/nginx/conf/conf.d/"$(pwd | sed 's/\// /g' | awk '{print $4}')".ssl.conf
    done
      sed -iE '/rocket-nginx\/default.conf/s/#\?include /include /g' /usr/local/nginx/conf/conf.d/"$(pwd | sed 's/\// /g' | awk '{print $4}')".ssl.conf
    else
      sed -i '/rediscache_/a\ \ include /usr/local/nginx/conf/rocket-nginx/default.conf\;' /usr/local/nginx/conf/conf.d/"$(pwd | sed 's/\// /g' | awk '{print $4}')".ssl.conf
    fi

  elif grep -q "rocket-nginx/default.conf" /usr/local/nginx/conf/conf.d/"$(pwd | sed 's/\// /g' | awk '{print $4}')".ssl.conf ; then
    for i in wpsupercache_ wpcacheenabler_ rediscache_
      do
        sed -iE "/$i/s/#\?include /#include /g" /usr/local/nginx/conf/conf.d/"$(pwd | sed 's/\// /g' | awk '{print $4}')".ssl.conf
    done
      sed -iE '/rocket-nginx\/default.conf/s/#\?include /include /g' /usr/local/nginx/conf/conf.d/"$(pwd | sed 's/\// /g' | awk '{print $4}')".ssl.conf
    else
      sed -i '/rediscache_/a\ \ include /usr/local/nginx/conf/rocket-nginx/default.conf\;' /usr/local/nginx/conf/conf.d/"$(pwd | sed 's/\// /g' | awk '{print $4}')".ssl.conf
    fi

    sed -iE 's/#\?try_files /#try_files /g ; s/#try_files \$uri \$uri\/ \/index.php?q/try_files \$uri \$uri\/ \/index.php?q/g' /usr/local/nginx/conf/conf.d/"$(pwd | sed 's/\// /g' | awk '{print $4}')".ssl.conf

else

wp plugin install cache-enabler --activate --allow-root --skip-plugins --skip-themes ; wp --allow-root --skip-plugins --skip-themes plugin delete comet-cache sg-cachepress wp-hummingbird wp-super-cache w3-total-cache nginx-helper wp-redis wp-fastest-cache --allow-root --skip-plugins --skip-themes ; chown -R nginx: .

sed -i '/location \/ {/i \ \ #if ($http_accept ~* "webp"){\n  #rewrite ^/(.*).(jpe\?g|png)\$ \/wp-content\/plugins\/webp-express\/wod\/webp-on-demand.php?wp-content=wp-content break;\n  #}\n \n  #include /usr/local/nginx/conf/webplocations.conf; \n' /usr/local/nginx/conf/conf.d/"$(pwd | sed 's/\// /g' | awk '{print $4}')".ssl.conf

sed -i '/uploads|files/a \ \n location ~ ^\/wp-content\/plugins\/webp-express\/ {\n   include /usr/local/nginx/conf/php.conf;\n }\n' /usr/local/nginx/conf/wpincludes/"$(pwd | sed 's/\// /g' | awk '{print $4}')"/wpsecure_"$(pwd | sed 's/\// /g' | awk '{print $4}')".conf

fi

sed -i 's=#include /usr/local/nginx/conf/cloudflare.conf;=include /usr/local/nginx/conf/cloudflare.conf;=g' /usr/local/nginx/conf/conf.d/"$(pwd | sed 's/\// /g' | awk '{print $4}')".ssl.conf

# CACHING

# rm -f wp-content/object-cache.php; cp -rf wp-content/plugins/redis-cache/includes/object-cache.php wp-content/; sed -i '/^[[:blank:]]*\*/d;s/\/\*\*.*//' wp-config.php

# Add to the end of the wpconfig.php for object cache

#$redis_server = array(
#    'host'     => '127.0.0.1',
#    'port'     => 6379,
#    'auth'     => '',
#    'database' => 0, // Optionally use a specific numeric Redis database. Default is 0.
#);

#define('WP_CACHE_KEY_SALT', md5( DB_NAME ) );
#define('WP_REDIS_SELECTIVE_FLUSH', true);
#define('WP_REDIS_DATABASE', 0);

# Add to the end of the wpconfig.php for object cache

if [ ! -f bigscoots.html ]; then

{
  echo "Congratulations! If you can see this, you are seeing your site load on a BigScoots server."
  echo "<p>"
  echo "<a href=\"/\"> Click here to go back to the homepage </a>"
} >> bigscoots.html
chown nginx: bigscoots.html

fi

if ! grep -q 'The servers opcache has been flushed' *.php ; then

opcachephp=$(cat /dev/urandom | tr -cd 'a-f0-9' | head -c 32).php ;
{
  echo "<?php"
  echo "echo 'The servers opcache has been flushed.';"
  echo "opcache_reset();"
  echo "?>"

} >> "$opcachephp"
chown nginx: "$opcachephp"

fi

touch apple-touch-icon-120x120-precomposed.png
touch apple-touch-icon-120x120.png
touch apple-touch-icon-152x152-precomposed.png
touch apple-touch-icon-152x152.png
touch apple-touch-icon-76x76-precomposed.png
touch apple-touch-icon-76x76.png
touch apple-touch-icon-precomposed.png
touch apple-touch-icon.png

chown -R nginx: /home/nginx/domains &
find . -type f -exec chmod 644 {} \; &
find . -type d -exec chmod 755 {} \; &
