#!/bin/bash

exit_on_error() {
    exit_code=$1
    last_command=${@:2}
    if [ "$exit_code" -ne 0 ]; then
        >&2 echo "\"${last_command}\" command failed with exit code ${exit_code}."
        exit "$exit_code"
    fi
}

WPCLIFLAGS="--allow-root --skip-plugins --skip-themes"

# Pre-checks
# remove add_filter should be used in a mu-plugin, otherwise breaks wp-cli

sed -i 's/add_filter/\/\/add_filter/g' wp-config.php

if ! hash dos2unix 2>/dev/null; then
    yum -y install dos2unix
fi

dos2unix wp-config.php

NGINX=$(which nginx)

NEW_DB_NAME=$(wp ${WPCLIFLAGS} config get DB_NAME)
NEW_DB_USER=$(wp ${WPCLIFLAGS} config get DB_USER)
NEW_DB_PASSWORD=$(wp ${WPCLIFLAGS} config get DB_PASSWORD)

if [[ $1 == cpanel ]]; then

  if [[ ! $(pwd | sed 's/\// /g' | grep -oE '[^ ]+$')  == public ]]; then
  echo "You are not curently in the public directory please cd into the  proper directory then try again."
  exit
  fi

  backup=$(echo *.tar.gz | sed 's/.tar.gz//g')
  mv "${backup}".tar.gz ..
  rm -rf *
  mv ../"${backup}".tar.gz .
  tar -zxvf "$backup".tar.gz
  sed -i '/gd-config.php/d' "$backup"/homedir/public_html/wp-config.php
  sed -i '/SiteGround/d' "$backup"/homedir/public_html/wp-config.php
  DB_NAME=$(wp ${WPCLIFLAGS} config get DB_NAME --path="$backup"/homedir/public_html/)
  mv "$backup"/mysql/"$DB_NAME".sql bigscoots.sql
  mv "$backup"/homedir/public_html/* .
  mv "$backup"/homedir/public_html/.htaccess .
fi

if [[ $1 == wpe ]]; then

  if [[ ! $(pwd | sed 's/\// /g' | grep -oE '[^ ]+$')  == public ]]; then
  echo "You are not curently in the public directory please cd into the  proper directory then try again."
  exit
  fi

  mv site-archive-*.zip wp-config.php ..
  rm -rf * .htaccess
  mv ../site-archive-*.zip .
  unzip site-archive-*.zip

  DB_CHARSET=$(wp ${WPCLIFLAGS} config get DB_CHARSET)
  DB_COLLATE=$(wp ${WPCLIFLAGS} config get DB_COLLATE)
  TABLE_PREFIX=$(wp ${WPCLIFLAGS} config get table_prefix)

  mv wp-config.php wp-config.php.wpe
  mv ../wp-config.php .
  mv wp-content/mysql.sql bigscoots.sql

  wp ${WPCLIFLAGS} config set DB_CHARSET "$DB_CHARSET"
  wp ${WPCLIFLAGS} config set DB_COLLATE "$DB_COLLATE"
  wp ${WPCLIFLAGS} config set table_prefix "$TABLE_PREFIX"
  wp ${WPCLIFLAGS} db reset --yes
fi

if [[ $1 == flywheel ]]; then

read -e -p "Enter db table prefix:" -i  "wp_" TABLE_PREFIX
TABLE_PREFIX=${TABLE_PREFIX:-wp_}

rm -rfv wp-content
unzip $(ls *.zip)

wp ${WPCLIFLAGS} db reset --yes
wp ${WPCLIFLAGS} config set table_prefix "$TABLE_PREFIX"
mv backup.sql bigscoots.sql
rsync -ahv --exclude wp-content files/ .
mv files/wp-content .
rm -rfv files

fi

if [[ $1 == fresh ]]; then

  DOMAIN=$(echo "$(pwd)"| sed "s=/home/nginx/domains/==g ; s=/public==g")
  wpuser=$(wp ${WPCLIFLAGS} user list --role=administrator --field=user_login)
  wplog=$(grep -rl $wpuser /root/centminlogs/*wordpress_addvhost.log)
  wpuserpass=$(grep "Wordpress Admin Pass:" $wplog | awk '{print $4}')

  wp ${WPCLIFLAGS} search-replace http: https:

  {
  echo "Wordpress Admin URL: https://$DOMAIN/wp-login.php"
  echo "Wordpress Admin User: $wpuser"
  echo "Wordpress Admin Pass: $wpuserpass"
  } >> /home/nginx/domains/"$DOMAIN"/.fresh

else

  if [ ! -f wp-config.php ]; then
  echo "wp-config.php doesn't exist, quitting."
  exit 1
  fi

  sed -i '/gd-config.php/d' wp-config.php
  sed -i '/SiteGround/d' wp-config.php

wp ${WPCLIFLAGS} config set DB_NAME "${NEW_DB_NAME}"
wp ${WPCLIFLAGS} config set DB_USER "${NEW_DB_USER}"
wp ${WPCLIFLAGS} config set DB_PASSWORD "${NEW_DB_PASSWORD}"
wp ${WPCLIFLAGS} db import bigscoots.sql

exit_on_error $? MySQL Import

mv bigscoots.sql ../

fi

# remove unnecessary files

rm -rfv wp-content/mu-plugins/SupportCenterMUAutoloader.php  wp-content/mu-plugins/et-safe-mode  wp-content/mu-plugins/wp-stack-cache.php wp-content/plugins/mojo-marketplace-wp-plugin wp-content/mu-plugins/force-strong-passwords wp-content/mu-plugins/mu-plugin.php wp-content/mu-plugins/slt-force-strong-passwords.php wp-content/mu-plugins/stop-long-comments.php wp-content/mu-plugins/wpengine-common wp-content/object-cache.php wp-content/mu-plugins/endurance-* wp-content/mu-plugins/liquidweb_mwp.php wp-content/mu-plugins/lw-varnish-cache-purger.php wp-content/mu-plugins/lw_disable_nags.php wp-content/mu-plugins/kinsta-mu-plugins* wp-content/cache wp-content/object-cache.php wp-content/db.php .user.ini wordfence-waf.php

# sed -i '/^[[:blank:]]*\*/d;s/\/\*\*.*//;/^$/d' wp-config.php

# remove unnecessary files

# Caching setups, only do 1 - START

# redis
# wp plugin install nginx-helper --activate --allow-root --skip-plugins  ; wp plugin delete comet-cache sg-cachepress wp-hummingbird wp-super-cache w3-total-cache wp-redis wp-fastest-cache wp-rocket litespeed-cache --allow-root --skip-plugins --skip-themes ; chown -R nginx: .


# CACHING

#!/bin/bash

sslconf=$(echo /usr/local/nginx/conf/conf.d/"$(pwd | sed 's/\// /g' | awk '{print $4}')".ssl.conf)

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

  fi

  if ! grep -q "rocket-nginx/default.conf" "${sslconf}" ; then

    sed -i '/rediscache_/a\ \ include /usr/local/nginx/conf/rocket-nginx/default.conf\;' "${sslconf}"

  fi

  sed -i 's/#include \/usr\/local\/nginx\/conf\/rocket-nginx\/default.conf;/include \/usr\/local\/nginx\/conf\/rocket-nginx\/default.conf;/g' "${sslconf}"

  for i in wpsupercache_ wpcacheenabler_ rediscache_ ; do

    if [[ ! $(grep $i "${sslconf}") =~ ^# ]]; then

      sed -i "/$i/s/#\?include /#include /g" "${sslconf}"

    fi

  done

  sed -i 's/#\?try_files /#try_files /g ; s/#try_files \$uri \$uri\/ \/index.php?\$/try_files \$uri \$uri\/ \/index.php?\$/g' "${sslconf}"

else

wp plugin install cache-enabler --activate ${WPCLIFLAGS} --quiet ; wp plugin delete comet-cache sg-cachepress wp-hummingbird wp-super-cache w3-total-cache nginx-helper wp-redis wp-fastest-cache ${WPCLIFLAGS} --quiet

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

# flush opcache muplugin on updates

mkdir -p wp-content/mu-plugins
rsync -ahv /bigscoots/wpo/extras/clear-opcode-caches.php wp-content/mu-plugins/

if [[ "$wprocket" == "y" ]]; then

  rm -f wp-content/advanced-cache.php

  wp plugin ${WPCLIFLAGS} deactivate wp-rocket
  wp plugin ${WPCLIFLAGS} activate wp-rocket

  echo "wprocket is detected check /usr/local/nginx/conf/conf.d/$i.ssl.conf for proper config" | mail -s "WPO  $i  $HOSTNAME - wprocket is detected check config" monitor@bigscoots.com

fi

if [[ $(wp option get siteurl ${WPCLIFLAGS}) =~ http:// ]]; then
        HTTPDOMAIN=$(wp option get siteurl ${WPCLIFLAGS})
        HTTPSDOMAIN=$(wp option get siteurl ${WPCLIFLAGS} | sed 's/http:/https:/g')
        wp search-replace "${HTTPDOMAIN}" "${HTTPSDOMAIN}" --skip-columns=guid ${WPCLIFLAGS}
fi

if [[ $(wp option get siteurl ${WPCLIFLAGS}) =~ https:// ]]; then
    /bigscoots/wpo_forcehttps.sh $(pwd | sed 's/\// /g' | awk '{print $4}')

    "$NGINX" -t > /dev/null 2>&1
    if [ $? -eq 0 ]; then
                npreload > /dev/null 2>&1
        else
                "$NGINX" -t 2>&1 | mail -s "WPO URGENT - Nginx conf fail forcing https /usr/local/nginx/conf/conf.d/$(pwd | sed 's/\// /g' | awk '{print $4}').conf for www -  $HOSTNAME" monitor@bigscoots.com
    fi
fi

if [[ $(wp option get siteurl ${WPCLIFLAGS}) =~ //www. ]]; then
    sed -i -E 's/return 301 https:\/\/(www)?/return 301 https:\/\/www./g' /usr/local/nginx/conf/conf.d/$(pwd | sed 's/\// /g' | awk '{print $4}').conf

    "$NGINX" -t > /dev/null 2>&1
    if [ $? -eq 0 ]; then
                npreload > /dev/null 2>&1
        else
                "$NGINX" -t 2>&1 | mail -s "WPO URGENT - Nginx conf fail during updating /usr/local/nginx/conf/conf.d/$(pwd | sed 's/\// /g' | awk '{print $4}').conf for www -  $HOSTNAME" monitor@bigscoots.com
    fi
fi

chown -R nginx: /home/nginx/domains &
find . -type f -exec chmod 644 {} \; &
find . -type d -exec chmod 755 {} \; &
