#!/bin/bash
#
# Justin Catello - bigscoots.com
#

##            ##
# CHANGE THESE #
##            ##

livesite="$1"
devsite="$2"

##                           ##
# NO MORE CHANGING BELOW HERE #
##                           ##

NGINX=$(which nginx)

if [ ! -d "/home/nginx/domains/$livesite" ] && [ ! -d "/home/nginx/domains/$devsite" ]; then
    echo "Domain doesn't exist."
    exit
fi

livedocroot=/home/nginx/domains/$livesite/public
devdocroot=/home/nginx/domains/$devsite/public
livedb=$(grep DB_NAME "$livedocroot"/wp-config.php | grep -v WP_CACHE_KEY_SALT | cut -d \' -f 4)
devdb=$(grep DB_NAME "$devdocroot"/wp-config.php | grep -v WP_CACHE_KEY_SALT | cut -d \' -f 4)

echo
echo
echo "Syncing files from $livesite to $devsite."
echo
echo

sleep 3

rsync -ahv --delete --exclude wp-content/uploads/backup --exclude 'wp-content/backup*' --exclude wp-content/uploads/backup-guard --exclude wp-snapshots --exclude wp-content/ai1wm-backups --exclude wp-config.php --exclude 'wp-content/uploads/backupbuddy*' --exclude wp-content/uploads/ShortpixelBackups --exclude wp-content/backup-db --exclude wp-content/updraft --exclude wp-content/cache/ --exclude wp-content/wpbackitup_backups "$livedocroot/" "$devdocroot/"

sleep 3

echo
echo
echo "Syncing files completed."
echo
echo

sleep 3

echo "Pulling live database from $livedocroot/wp-config.php"
echo
echo

sleep 1

echo "Pulling dev database from $devdocroot/wp-config.php"
echo
echo

sleep 2

echo "Live database: $livedb"

sleep 1

echo "Dev database: $devdb"
echo
echo

sleep 3

echo "Backing up $devdb to ${devdocroot//public/backup}"
echo
echo

mkdir -p "${devdocroot//public/backup}/$(date +%Y-%m-%d)"
mysqldump "$devdb" --single-transaction --quick --opt --skip-lock-tables --routines --triggers | gzip > "${devdocroot//public/backup}/$(date +%Y-%m-%d)/$devdb$(date +%H%M).sql.gz"
sleep 1

echo "Backed up $devdb to ${devdocroot//public/backup}/$(date +%Y-%m-%d)/$devdb$(date +%H%M).sql.gz"
echo
echo

sleep 3

echo "Dropping all tables in $devdb"
echo
echo

mysql -e "SHOW TABLES FROM $devdb" | grep -v "Tables_in_$devdb" | while read -r a; do mysql -e "DROP TABLE $devdb.$a" ; done

sleep 1

echo "Dropped all tables in $devdb"
echo
echo

sleep 2

echo "Importing database from $livedb to $devdb"
echo
echo

mysqldump "$livedb" --single-transaction --quick --opt --skip-lock-tables --routines --triggers| mysql -f "$devdb"


sleep 1

echo "Importing database has been completed."
echo
echo "Changing the database prefix in the dev wp-config.php"

sed -i "/table_prefix/c\\$(grep _prefix "$livedocroot"/wp-config.php | grep -v WP_CACHE_KEY_SALT)" "$devdocroot"/wp-config.php

sleep 1

echo "Table prefix has been updated in $devdocroot/wp-config.php"
echo
echo "Changing all instances of $livesite to $devsite in the database."

cd "$livedocroot/" || exit
siteurl=$(wp option get siteurl --allow-root | sed -r 's/https?:\/\///g')
cd "$devdocroot/" || exit
wp search-replace "//$siteurl" "//$devsite" --recurse-objects --skip-columns=guid --skip-tables=wp_users --allow-root --skip-plugins --skip-themes


sleep 1

echo "All instances have been changed."
echo
echo

sleep 1

        if [ -n "$3" ] && [ -n "$4" ]; then

        echo "htpasswd detected, applying now."
        echo
        echo

        if  ! grep -q wpolocksite /usr/local/nginx/conf/conf.d/"$2".ssl.conf ; then

        /usr/local/nginx/conf/htpasswd.sh create /home/nginx/domains/"$2"/wpolocksite "$3" "$4"
        sed -i "/location \/ {/a \  auth_basic_user_file /home/nginx/domains/$2/wpolocksite;" /usr/local/nginx/conf/conf.d/"$2".ssl.conf
        sed -i "/location \/ {/a \  auth_basic \"Private\";" /usr/local/nginx/conf/conf.d/"$2".ssl.conf

        echo "htpasswd applied"
                echo
                echo

                sleep 1

        else

        /usr/local/nginx/conf/htpasswd.sh create /home/nginx/domains/"$2"/wpolocksite "$3" "$4"

                echo "htpasswd applied"
                echo
                echo

                sleep 1

        fi

        fi

sleep 1

echo "Correcting all ownership and permissions."
echo
echo

chown -R nginx: /home/nginx/domains/$devsite

echo "Done. Reloading nginx and flushing Redis cache."
echo
echo

redis-cli flushall

"$NGINX" -t > /dev/null 2>&1
    if [ $? -eq 0 ]; then
                npreload > /dev/null 2>&1
        else
                "$NGINX" -t 2>&1 | mail -s "WPO URGENT - Nginx conf fail during staging request -  $HOSTNAME" monitor@bigscoots.com
                exit 1
    fi

echo "Syncing $livesite to $devsite has been completed."
echo
echo
