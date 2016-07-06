#!/bin/bash
# Usage: /bigscoots/ngxbackup.sh /home/nginx/domain.com/public daily,weekly,monthly

# Touch
BKUSER=0000
DOCROOT=$1
FREQUENCY=$2
DBSERVER=int-backup2.bigscoots.com

# No Touch
DB=$(grep DB_NAME "$DOCROOT"/wp-config.php | grep -Ev '//define' | sed -e "s/define('DB_NAME', '//g" -e "s/');//g" | tr -d '\r')
SITE=$(echo "$DOCROOT" | sed -e "s/\/home\/nginx\/domains\///g" -e "s/\/public//g")
CURRDATE=$(date +%Y-%m-%d)
MYSQLDUMP=$(which mysqldump)

# Remove old backups
ssh "$BKUSER"@$DBSERVER 'find ~/backup/$FREQUENCY/ -type d -ctime +25 -exec rm -rf {} \;'

# Create the backup directory on the backup server
ssh "$BKUSER"@$DBSERVER "mkdir -p ~/backup/$FREQUENCY/$CURRDATE"

# Backup the database into the sites docroot
$MYSQLDUMP "$DB" | gzip > "$DOCROOT"/"$DB".sql.gz

# Tarbal the entire site including database directly onto the backup server
tar zvcf - "$DOCROOT" --exclude='cache' | ssh "$BKUSER"@$DBSERVER "cat > ~/backup/$FREQUENCY/$CURRDATE/$SITE.tar.gz"

# Remove the database backup from the sites docroot
rm -f "$DOCROOT"/"$DB".sql.gz

# The end
