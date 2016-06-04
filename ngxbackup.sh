#!/bin/bash

BKUSER=0000
DOCROOT=/home/nginx/domains/domain.com/public
DB=$(grep DB_NAME $DOCROOT/wp-config.php | sed -e "s/define('DB_NAME', '//g" -e "s/');//g" | tr -d '\r')
SITE=$(echo "$DOCROOT" | sed -e "s/\/home\/nginx\/domains\///g" -e "s/\/public//g")

ssh "$BKUSER"@int-backup2.bigscoots.com 'mkdir -p ~/backup/"$(date +%Y-%m-%d)"'

mysqldump "$DB" | gzip > $DOCROOT/"$DB".sql.gz

tar zcf - "$DOCROOT" | ssh "$BKUSER"@int-backup2.bigscoots.com "cat > ~/backup/$(date +%Y-%m-%d)/$SITE.tar.gz"

rm -f $DOCROOT/"$DB".sql.gz

ssh "$BKUSER"@int-backup2.bigscoots.com 'find ~/backup/ -type d -ctime +3 -exec rm -rf {} \;'
