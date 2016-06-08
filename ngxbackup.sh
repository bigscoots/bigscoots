#!/bin/bash

# Touch
BKUSER=0000
DOCROOT=/home/nginx/domains/domain.com/public
DBSERVER=int-backup2.bigscoots.com

# No Touch
DB=$(grep DB_NAME $DOCROOT/wp-config.php | sed -e "s/define('DB_NAME', '//g" -e "s/');//g" | tr -d '\r')
SITE=$(echo "$DOCROOT" | sed -e "s/\/home\/nginx\/domains\///g" -e "s/\/public//g")
CURRDATE=$(date +%Y-%m-%d)

# Remove old backups
ssh "$BKUSER"@$DBSERVER 'find ~/backup/ -type d -ctime +3 -exec rm -rf {} \;'

# Create the backup directory on the backup server
ssh "$BKUSER"@$DBSERVER "mkdir -p ~/backup/$CURRDATE"

# Backup the database into the sites docroot
mysqldump "$DB" | gzip > $DOCROOT/"$DB".sql.gz

# Tarbal the entire site including database directly onto the backup server
tar zcf - "$DOCROOT" | ssh "$BKUSER"@$DBSERVER "cat > ~/backup/$CURRDATE/$SITE.tar.gz"

# Remove the database backup from the sites docroot
rm -f $DOCROOT/"$DB".sql.gz

# The end
