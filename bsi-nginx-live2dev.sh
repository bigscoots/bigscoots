#!/bin/bash
#
# Justin Catello - bigscoots.com
#

##            ##
# CHANGE THESE #
##            ##

livesite=fitwerx.com
devsite=temp.fitwerx.com

##                           ##
# NO MORE CHANGING BELOW HERE #
##                           ##

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

rsync -ahv --delete --exclude wp-config.php --exclude wp-content/updraft --exclude wp-content/cache/ "$livedocroot/" "$devdocroot/"

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
mysqldump "$devdb" | gzip > "${devdocroot//public/backup}/$(date +%Y-%m-%d)/$devdb$(date +%H%M).sql.gz"

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

mysqldump "$livedb" | mysql "$devdb"

sleep 1

echo "Importing database has been completed."
echo
echo

sleep 1

echo "Changing all instances of $livesite to $devsite in the database."
echo
echo

cd "$devdocroot/" || exit
wp --allow-root search-replace "$livesite" "$devsite" --skip-plugins --skip-themes

sleep 1

echo "All instances have been changed."
echo
echo

sleep 1

echo "Correcting all ownership and permissions."
echo
echo

chown -R nginx: /home/nginx/domains/

echo "Done."
echo
echo


sleep 1

echo "Syncing $livesite to $devsite has been completed."
echo
echo
