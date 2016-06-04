#!/bin/bash

# Touch

BKUSER=0000
DOCROOT=/home/nginx/domains/domain.com/public
DBSERVER=int-backup2.bigscoots.com

# No Touch

DB=$(grep DB_NAME $DOCROOT/wp-config.php | sed -e "s/define('DB_NAME', '//g" -e "s/');//g" | tr -d '\r')
SITE=$(echo "$DOCROOT" | sed -e "s/\/home\/nginx\/domains\///g" -e "s/\/public//g")
CURRDATE=$(date +%Y-%m-%d)

ssh "$BKUSER"@$DBSERVER 'mkdir -p ~/backup/"$CURRDATE"'

mysqldump "$DB" | gzip > $DOCROOT/"$DB".sql.gz

tar zcf - "$DOCROOT" | ssh "$BKUSER"@$DBSERVER "cat > ~/backup/$CURRDATE/$SITE.tar.gz"

rm -f $DOCROOT/"$DB".sql.gz

ssh "$BKUSER"@$DBSERVER 'find ~/backup/ -type d -ctime +3 -exec rm -rf {} \;'
