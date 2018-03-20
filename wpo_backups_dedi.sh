#!/bin/bash

date=$(date "+%Y-%m-%dT%H_%M_%S")
HOMEDIR=/home/nginx/domains/

if [ ! -f "$HOMEDIR".rsync/exclude ]; then
        mkdir -p "$HOMEDIR".rsync

        {
        echo "log"
        echo "*/core.[0-9]*"
        echo "*/error_log"
        echo "*/wp-content/updraft"
        echo "*/wp-content/cache"

        } > "$HOMEDIR".rsync/exclude
else
        :
fi

for wpinstall in $(find "$HOMEDIR"*/public/ -type f -name wp-config.php | sed 's/wp-config.php//g')
   do
    dbname=$(grep DB_NAME "$wpinstall"/wp-config.php | grep -v WP_CACHE_KEY_SALT | cut -d \' -f 4)
    /usr/bin/mysqldump "$dbname" | gzip > "$wpinstall$dbname".sql.gz
done

rsync -azP \
  --delete \
  --delete-excluded \
  --exclude-from="$HOMEDIR"/.rsync/exclude \
  --link-dest=../current \
  "$HOMEDIR" /backup/incomplete_back-"$date"

  mv /backup/incomplete_back-"$date" /backup/back-"$date" \
  && rm -f /backup/current \
  && ln -s /backup/back-"$date" /backup/current

for wpinstall in $(find "$HOMEDIR"*/public/ -type f -name wp-config.php | sed 's/wp-config.php//g')
   do
    dbname=$(grep DB_NAME "$wpinstall"/wp-config.php | grep -v WP_CACHE_KEY_SALT | cut -d \' -f 4)
    rm -f "$wpinstall$dbname".sql.gz
done
