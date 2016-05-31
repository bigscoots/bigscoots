#!/bin/bash

DOCROOT=/home/nginx/domains/domain.com/public
DB=$(grep DB_NAME $DOCROOT/wp-config.php | sed -e "s/define('DB_NAME', '//g" -e "s/');//g")
SITE=$(echo "$DOCROOT" | sed -e "s/\/home\/nginx\/domains\///g" -e "s/\/public//g")

mkdir -p /backup/DATE="$(date +%Y-%m-%d)/$SITE"
mysqldump "$DB" | gzip > $DOCROOT/"$DB".sql.gz 
tar -zcf /backup/DATE="$(date +%Y-%m-%d)"/"$SITE".tar.gz "$DOCROOT"
rm -f $DOCROOT/"$DB".sql.gz
find /backup/ -type f -iname '*.tar.gz' ctime +14 -exec rm {} \;
