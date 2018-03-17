#!/bin/bash

date=$(date "+%Y-%m-%dT%H_%M_%S")
HOMEDIR=/home/nginx/domains/
BKUSER=wpo$(awk '{print $1}' /proc/vz/veinfo)
BKSVR=int-backup3.bigscoots.com

if ssh -i "$HOME"/.ssh/wpo_backups "$BKUSER"@"$BKSVR" 'uptime'; [ $? -eq 255 ]
then
  echo "Mark for Justin" | mail -s "$HOSTNAME- WPO failed to SSH to backup server." monitor@bigscoots.com
  exit 1
fi

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

for wpinstall in $(find /home/nginx/domains/*/public/ -type f -name wp-config.php | sed 's/wp-config.php//g')
   do
    dbname=$(grep DB_NAME "$wpinstall"/wp-config.php | grep -v WP_CACHE_KEY_SALT | cut -d \' -f 4)
    /usr/bin/mysqldump "$dbname" | gzip > "$wpinstall$dbname".sql.gz
done

rsync -azP \
  -e "ssh -i $HOME/.ssh/wpo_backups" \
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
