#!/bin/bash

date=$(date "+%Y-%m-%dT%H_%M_%S")
HOMEDIR=/home/nginx/domains/
BKUSER=wpo$(awk '{print $1}' /proc/vz/veinfo)
BKSVR=int-backup3.bigscoots.com

for wpinstall in $(find /home/nginx/domains/*/public/ -type f -name wp-config.php | sed 's/wp-config.php//g')
   do
    dbname=$(grep DB_NAME "$wpinstall"/wp-config.php | grep -v WP_CACHE_KEY_SALT | cut -d \' -f 4)
    /usr/bin/mysqldump "$dbname" | gzip > "$wpinstall$dbname".sql.gz
done

rsync -azP \
  --delete \
  --delete-excluded \
  --exclude-from="$HOMEDIR".rsync/exclude \
  --link-dest=../current \
  "$HOMEDIR" "$BKUSER"@"$BKSVR":incomplete_back-"$date" \
  && ssh -i "$HOME"/.ssh/wpo_backups "$BKUSER"@"$BKSVR" \
  "mv incomplete_back-$date back-$date \
  && rm -f current \
  && ln -s back-$date current"

for wpinstall in $(find /home/nginx/domains/*/public/ -type f -name wp-config.php | sed 's/wp-config.php//g')
   do
    dbname=$(grep DB_NAME "$wpinstall"/wp-config.php | grep -v WP_CACHE_KEY_SALT | cut -d \' -f 4)
    rm -f "$wpinstall$dbname".sql.gz
done
