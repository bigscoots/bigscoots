#!/bin/bash

#
# Justin Catello - bigscoots.com
#

sourcesite="$1"
destinationsite="$2"


WPCLIFLAGS="--allow-root --skip-plugins --skip-themes"
NGINX=$(which nginx)

if [ ! -d "/home/nginx/domains/$sourcesite" ] && [ ! -d "/home/nginx/domains/$destinationsite" ]; then
    exit 2
fi

sourcesitedocroot=/home/nginx/domains/"${sourcesite}"/public
destinationsitedocroot=/home/nginx/domains/"${destinationsite}"/public

if ! sourcesitedb=$(wp ${WPCLIFLAGS} config get DB_NAME --path=${sourcesitedocroot} 2>&1); then
    exit 3
fi

if ! destinationsitedb=$(wp ${WPCLIFLAGS} config get DB_NAME --path=${destinationsitedocroot} 2>&1); then
    exit 3
fi

if [[ $sourcesitedb == $destinationsitedb ]]; then
    if ! wp ${WPCLIFLAGS} config set DB_NAME "$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 16)" --path=${destinationsitedocroot} 2>&1; then
        exit
    fi
    if ! wp ${WPCLIFLAGS} config set DB_USER "$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 16)" --path=${destinationsitedocroot} 2>&1; then
        exit
    fi
    if ! wp ${WPCLIFLAGS} config set DB_PASSWORD "$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 16)" --path=${destinationsitedocroot} 2>&1; then
        exit
    fi
    if ! wp ${WPCLIFLAGS} db create 2>&1; then
        exit
    fi
fi

rsync -aqhv --delete \
--exclude 'wp-content/uploads/backupbuddy*' \
--exclude 'wp-content/backup*' \
--exclude wp-content/uploads/backup \
--exclude wp-content/uploads/backup-guard \
--exclude wp-snapshots \
--exclude wp-content/ai1wm-backups \
--exclude wp-config.php \
--exclude wp-content/uploads/ShortpixelBackups \
--exclude wp-content/backup-db \
--exclude wp-content/updraft \
--exclude wp-content/cache/ \
--exclude wp-content/wpbackitup_backups \
"$sourcesitedocroot/" "$destinationsitedocroot/"

wp ${WPCLIFLAGS} db reset --yes --path="${destinationsitedocroot}" --quiet 2>&1
wp ${WPCLIFLAGS} db export - --path="${sourcesitedocroot}" --quiet | wp ${WPCLIFLAGS} --quiet db import - --path="${destinationsitedocroot}" --quiet 2>&1
wp ${WPCLIFLAGS} config set table_prefix $(wp ${WPCLIFLAGS} config get table_prefix --path="${sourcesitedocroot}") --path="${destinationsitedocroot}" --quiet 2>&1
siteurl=$(wp ${WPCLIFLAGS} option get siteurl --path="${sourcesitedocroot}" --quiet | sed -r 's/https?:\/\///g')
wp ${WPCLIFLAGS} search-replace "//$siteurl" "//$destinationsite" --recurse-objects --skip-columns=guid --skip-tables=wp_users --path="${destinationsitedocroot}" --quiet


if [ -n "$3" ] && [ -n "$4" ]; then

    if  ! grep -q wpolocksite /usr/local/nginx/conf/conf.d/"$2".ssl.conf ; then

        /usr/local/nginx/conf/htpasswd.sh create /home/nginx/domains/"$2"/wpolocksite "$3" "$4"
        sed -i "/location \/ {/a \  auth_basic_user_file /home/nginx/domains/$2/wpolocksite;" /usr/local/nginx/conf/conf.d/"$2".ssl.conf
        sed -i "/location \/ {/a \  auth_basic \"Private\";" /usr/local/nginx/conf/conf.d/"$2".ssl.conf

    else

        /usr/local/nginx/conf/htpasswd.sh create /home/nginx/domains/"$2"/wpolocksite "$3" "$4"

    fi
fi

if [ -d "wp-content/plugins/wp-rocket" ]; then

    rm -f wp-content/advanced-cache.php
    wp plugin ${WPCLIFLAGS} deactivate wp-rocket
    wp plugin ${WPCLIFLAGS} activate wp-rocket

fi

chown -R nginx: /home/nginx/domains/$destinationsite

redis-cli flushall > /dev/null 2>&1

"$NGINX" -t > /dev/null 2>&1
    if [ $? -eq 0 ]; then
                npreload > /dev/null 2>&1
        else
                "$NGINX" -t 2>&1 | mail -s "WPO URGENT - Nginx conf fail during staging request -  $HOSTNAME" monitor@bigscoots.com
                exit 1
    fi
