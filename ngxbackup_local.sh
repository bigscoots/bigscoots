#!/bin/bash
# Usage: /bigscoots/ngxbackup.sh /home/nginx/domains/domain.com/public daily,weekly,monthly

# Touch
docroot=$1
frequency=$2

# No Touch
db=$(grep DB_NAME "$docroot"/wp-config.php | grep -v WP_CACHE_KEY_SALT | cut -d \' -f 4)
site=$(echo "$docroot" | sed -e "s/\/home\/nginx\/domains\///g" -e "s/\/public//g")
currdate=$(date +%Y-%m-%d-%H%M)
bfile=${site}_${currdate}

# Create the backup directory on the backup server
echo "Creating the backup directory for $site on the backup server: /backup/$site/$frequency"
mkdir -p /backup/"$site"/"$frequency"

# Remove old backups
find /backup/"$site"/"$frequency"/ -type d -ctime +120 -exec rm -rf {} \;

# Backup the database into the sites docroot
echo "Taking a backup of the database $db for $site"
mysqldump "$db" --single-transaction --quick --opt --skip-lock-tables --routines --triggers | gzip > "$docroot"/"$db".sql.gz

# Tarbal the entire site including database directly onto the backup server
echo "Now we are backing up the site files for $site"
tar -zcvf /backup/"$site"/"$frequency"/"$bfile".tar.gz "$docroot" ./ --exclude-from=/bigscoots/ngxbackup-excludes.txt --exclude="$docroot"/wp-content/uploads

# Remove the database backup from the sites docroot
echo "We are now removing he database backp from the source $docroot/$db.sql.gz"
rm -f "$docroot"/"$db".sql.gz

# rsync the uploads directory if it was excluded
echo "Running rsync for the $site"
mkdir -p /backup/"$site"/rsync
rsync -ah --exclude-from=/bigscoots/ngxbackup-excludes.txt "$docroot"/ /backup/"$site"/rsync/

# The end
