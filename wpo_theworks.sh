#!/bin/bash

exit_on_error() {
    exit_code=$1
    last_command=${@:2}
    if [ "$exit_code" -ne 0 ]; then
        >&2 echo "\"${last_command}\" command failed with exit code ${exit_code}."
        exit "$exit_code"
    fi
}

if [[ $1 == cpanel ]]; then
  backup=$(echo *.tar.gz | sed 's/.tar.gz//g')
  tar -zxvf "$backup".tar.gz
  sed -i '/gd-config.php/d' "$backup"/homedir/public_html/wp-config.php
  sed -i '/SiteGround/d' "$backup"/homedir/public_html/wp-config.php
  DB_NAME=$(wp --allow-root config get DB_NAME --path="$backup"/homedir/public_html/)
  mv "$backup"/mysql/"$DB_NAME".sql bigscoots.sql
  mv "$backup"/homedir/public_html/* .
  mv "$backup"/homedir/public_html/.htaccess .
  wp --allow-root --skip-plugins --skip-themes config set DB_HOST localhost
fi

if [[ $1 == wpe ]]; then

  unzip site-archive-*.zip

  DB_CHARSET=$(wp --allow-root --skip-plugins --skip-themes config get DB_CHARSET)
  DB_COLLATE=$(wp --allow-root --skip-plugins --skip-themes config get DB_COLLATE)
  TABLE_PREFIX=$(wp --allow-root --skip-plugins --skip-themes config get table_prefix)

  mv wp-config.php wp-config.php.wpe
  mv ../wp-config.php .
  mv wp-content/mysql.sql bigscoots.sql
  wp --allow-root --skip-plugins --skip-themes config set DB_CHARSET "$DB_CHARSET"
  wp --allow-root --skip-plugins --skip-themes config set DB_COLLATE "$DB_COLLATE"
  wp --allow-root --skip-plugins --skip-themes config set table_prefix "$TABLE_PREFIX"
  wp --allow-root --skip-plugins --skip-themes config set DB_HOST localhost
  wp --allow-root --skip-plugins --skip-themes db reset --yes
fi

if [[ $1 == flywheel ]]; then

read -e -p "Enter db table prefix:" -i  "wp_" TABLE_PREFIX
TABLE_PREFIX=${TABLE_PREFIX:-wp_}

rm -rfv wp-content
unzip $(ls *.zip)

wp --allow-root --skip-plugins --skip-themes db reset --yes
wp --allow-root --skip-plugins --skip-themes config set table_prefix "$TABLE_PREFIX"
mv backup.sql bigscoots.sql
rsync -ahv --exclude wp-content files/ .
mv files/wp-content .
rm -rfv files

fi

if [[ $1 == fresh ]]; then

  DOMAIN=$(echo "$(pwd)"| sed "s=/home/nginx/domains/==g ; s=/public==g")
  wpuser=$(wp --allow-root --skip-plugins --skip-themes user list --role=administrator --field=user_login)
  wplog=$(grep -rl $wpuser /root/centminlogs/*wordpress_addvhost.log)
  wpuserpass=$(grep "Wordpress Admin Pass:" $wplog | awk '{print $4}')

  wp --allow-root --skip-plugins --skip-themes search-replace http: https:
  /bigscoots/wpo_forcehttps.sh "$DOMAIN"
  nginx -t

  echo
  echo
  echo "Wordpress Admin URL: https://$DOMAIN/wp-login.php"
  echo "Wordpress Admin User: $wpuser"
  echo "Wordpress Admin Pass: $wpuserpass"
  echo
  echo

else

  if [ ! -f wp-config.php ]; then
  echo "wp-config.php doesn't exist, quitting."
  exit 1
  fi

  sed -i '/gd-config.php/d' wp-config.php
  sed -i '/SiteGround/d' wp-config.php

  if hash wp 2>/dev/null; then
  echo found wp-cli

  dbname=$(wp --allow-root --skip-plugins --skip-themes config get DB_NAME)
  dbuser=$(wp --allow-root --skip-plugins --skip-themes config get DB_USER)
  dbpass=$(wp --allow-root --skip-plugins --skip-themes config get DB_PASSWORD)
  wp --allow-root --skip-plugins --skip-themes config set DB_HOST localhost

  if grep -q FS_METHOD wp-config.php; then
  wp --allow-root --skip-plugins --skip-themes config delete FS_METHOD
  fi
  if grep -q FS_CHMOD_DIR wp-config.php; then
  wp --allow-root --skip-plugins --skip-themes config delete FS_CHMOD_DIR
  fi
  if grep -q FS_CHMOD_FILE wp-config.php; then
  wp --allow-root --skip-plugins --skip-themes config delete FS_CHMOD_FILE
  fi

  else

  dbname=$(grep DB_NAME wp-config.php | grep -v WP_CACHE_KEY_SALT | grep -v '^//' | cut -d \' -f 4 )
  dbuser=$(grep DB_USER wp-config.php | grep -v WP_CACHE_KEY_SALT | grep -v '^//' | cut -d \' -f 4 )
  dbpass=$(grep DB_PASSWORD wp-config.php | grep -v WP_CACHE_KEY_SALT | grep -v '^//' | cut -d \' -f 4 )

  fi

  echo
  echo
  echo "Database Name: $dbname"
  echo "Database User: $dbuser"
  echo "Database Password: $dbpass"
  echo "Creating database: $dbname"
  echo
  echo

  if [ ! -d /var/lib/mysql/"$dbname" ] ; then
    mysql -e "CREATE DATABASE $dbname;"
  fi

  echo "Assigning Database User: $dbuser to Database: $dbname using Password: $dbpass"
  /usr/bin/mysql -e "grant all privileges on $dbname.* to '$dbuser'@'localhost' identified by '$dbpass';"

wp --allow-root --skip-plugins --skip-themes db import bigscoots.sql
exit_on_error $? MySQL Import

mv bigscoots.sql ../

fi

# remove unnecessary files

rm -rfv wp-content/mu-plugins/SupportCenterMUAutoloader.php  wp-content/mu-plugins/et-safe-mode  wp-content/mu-plugins/wp-stack-cache.php wp-content/plugins/mojo-marketplace-wp-plugin wp-content/mu-plugins/force-strong-passwords wp-content/mu-plugins/mu-plugin.php wp-content/mu-plugins/slt-force-strong-passwords.php wp-content/mu-plugins/stop-long-comments.php wp-content/mu-plugins/wpengine-common wp-content/object-cache.php wp-content/mu-plugins/endurance-* wp-content/mu-plugins/liquidweb_mwp.php wp-content/mu-plugins/lw-varnish-cache-purger.php wp-content/mu-plugins/lw_disable_nags.php wp-content/mu-plugins/kinsta-mu-plugins* wp-content/cache wp-content/object-cache.php wp-content/db.php .user.ini wordfence-waf.php

sed -i '/^[[:blank:]]*\*/d;s/\/\*\*.*//;/^$/d' wp-config.php

# remove unnecessary files

# Caching setups, only do 1 - START

# redis
# wp plugin install nginx-helper --activate --allow-root --skip-plugins  ; wp plugin delete comet-cache sg-cachepress wp-hummingbird wp-super-cache w3-total-cache wp-redis wp-fastest-cache wp-rocket litespeed-cache --allow-root --skip-plugins --skip-themes ; chown -R nginx: .


# CACHING

if [ -d "wp-content/plugins/wp-rocket" ]; then

  wprocket=y

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
        sed -i "/$i/s/#\?include /#include /g" /usr/local/nginx/conf/conf.d/"$(pwd | sed 's/\// /g' | awk '{print $4}')".ssl.conf
    done
        sed -i '/rocket-nginx\/default.conf/s/#\?include/include/g' /usr/local/nginx/conf/conf.d/"$(pwd | sed 's/\// /g' | awk '{print $4}')".ssl.conf

    if grep -q "rocket-nginx/default.conf" /usr/local/nginx/conf/conf.d/"$(pwd | sed 's/\// /g' | awk '{print $4}')".ssl.conf ; then
    for i in wpsupercache_ wpcacheenabler_ rediscache_
      do
        sed -i "/$i/s/#\?include /#include /g" /usr/local/nginx/conf/conf.d/"$(pwd | sed 's/\// /g' | awk '{print $4}')".ssl.conf
    done
      sed -i '/rocket-nginx\/default.conf/s/#\?include /include /g' /usr/local/nginx/conf/conf.d/"$(pwd | sed 's/\// /g' | awk '{print $4}')".ssl.conf
    else
      sed -i '/rediscache_/a\ \ include /usr/local/nginx/conf/rocket-nginx/default.conf\;' /usr/local/nginx/conf/conf.d/"$(pwd | sed 's/\// /g' | awk '{print $4}')".ssl.conf
    fi

  elif grep -q "rocket-nginx/default.conf" /usr/local/nginx/conf/conf.d/"$(pwd | sed 's/\// /g' | awk '{print $4}')".ssl.conf ; then
    for i in wpsupercache_ wpcacheenabler_ rediscache_
      do
        sed -i "/$i/s/#\?include /#include /g" /usr/local/nginx/conf/conf.d/"$(pwd | sed 's/\// /g' | awk '{print $4}')".ssl.conf
    done
      sed -i '/rocket-nginx\/default.conf/s/#\?include /include /g' /usr/local/nginx/conf/conf.d/"$(pwd | sed 's/\// /g' | awk '{print $4}')".ssl.conf
    else
      sed -i '/rediscache_/a\ \ include /usr/local/nginx/conf/rocket-nginx/default.conf\;' /usr/local/nginx/conf/conf.d/"$(pwd | sed 's/\// /g' | awk '{print $4}')".ssl.conf
    fi

    sed -i 's/#\?try_files /#try_files /g ; s/#try_files \$uri \$uri\/ \/index.php?q/try_files \$uri \$uri\/ \/index.php?q/g' /usr/local/nginx/conf/conf.d/"$(pwd | sed 's/\// /g' | awk '{print $4}')".ssl.conf

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

{
echo     allow 192.0.64.0/18\;
echo     deny all\;
} >> /usr/local/nginx/conf/xmlrpcblock.conf

for i in $(ls /home/nginx/domains/ -1 | grep -v domains.txt)
        do
                if ! grep -q "xmlrpcblock.conf" /usr/local/nginx/conf/conf.d/"$i".ssl.conf ; then
                sed -i '/xmlrpc/a \    include /usr/local/nginx/conf/xmlrpcblock.conf;' /usr/local/nginx/conf/conf.d/"$i".ssl.conf
                fi
        done

touch apple-touch-icon-120x120-precomposed.png
touch apple-touch-icon-120x120.png
touch apple-touch-icon-152x152-precomposed.png
touch apple-touch-icon-152x152.png
touch apple-touch-icon-76x76-precomposed.png
touch apple-touch-icon-76x76.png
touch apple-touch-icon-precomposed.png
touch apple-touch-icon.png

if [[ "$wprocket" == "y" ]]; then

  echo "Removing old wp-content/advanced-cache.php"
  echo

  rm -f wp-content/advanced-cache.php

  echo "Deactivating wp-rocket"
  echo
  wp plugin --allow-root --skip-plugins --skip-themes deactivate wp-rocket

  echo "Activating wp-rocket"
  echo
  wp plugin --allow-root --skip-plugins --skip-themes activate wp-rocket

  echo "Correct path should now be set in wp-content/advanced-cache.php"

  echo
  echo "wprocket is detected check /usr/local/nginx/conf/conf.d/$i.ssl.conf for proper config"
  echo

fi

chown -R nginx: /home/nginx/domains &
find . -type f -exec chmod 644 {} \; &
find . -type d -exec chmod 755 {} \; &