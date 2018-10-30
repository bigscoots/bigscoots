#!/bin/bash

date=$(date "+%Y-%m-%dT%H_%M_%S")
HOMEDIR=/home/nginx/domains/
BKUSER=wpo$(awk '{print $1}' /proc/vz/veinfo)
BKSVR=backup3.bigscoots.com

if ssh -oStrictHostKeyChecking=no -i "$HOME"/.ssh/wpo_backups "$BKUSER"@"$BKSVR" 'uptime'; [ $? -eq 255 ]
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
        echo "*/wp-content/wpbackitup_backups"
        echo "*/wp-content/uploads/ithemes-security"
        echo "*/wp-content/uploads/wpallimport"
        echo "*/wp-content/uploads/ShortpixelBackups"

        } > "$HOMEDIR".rsync/exclude
else
        :
fi

for wpinstall in $(find /home/nginx/domains/*/public/ -type f -name wp-config.php | sed 's/wp-config.php//g')
   do
    dbname=$(grep DB_NAME "$wpinstall"/wp-config.php | grep -v WP_CACHE_KEY_SALT | cut -d \' -f 4)
    /usr/bin/mysqldump "$dbname" | gzip > "$wpinstall$dbname".sql.gz
done

rsync -ah --stats \
  -e "ssh -oStrictHostKeyChecking=no -i $HOME/.ssh/wpo_backups" \
  --delete \
  --delete-excluded \
  --exclude-from="$HOMEDIR".rsync/exclude \
  --link-dest=../current \
  "$HOMEDIR" "$BKUSER"@"$BKSVR":incomplete_back-"$date" \
  && ssh -oStrictHostKeyChecking=no -i "$HOME"/.ssh/wpo_backups "$BKUSER"@"$BKSVR" \
  "mv incomplete_back-$date back-$date \
  && rm -f current \
  && ln -s back-$date current"

ssh -oStrictHostKeyChecking=no -i /root/.ssh/wpo_backups "$BKUSER"@"$BKSVR" 'if [ ! -d "current" ]; then
mv $(ls -td -- */ | head -n 1 | cut -d'/' -f1) $(ls -td -- */ | head -n 1 | cut -d'/' -f1 | sed 's/incomplete_//g')
ln -s $(ls -td -- */ | head -n 1 | cut -d'/' -f1 | sed 's/incomplete_//g') current
fi'

for wpinstall in $(find /home/nginx/domains/*/public/ -type f -name wp-config.php | sed 's/wp-config.php//g')
   do
    dbname=$(grep DB_NAME "$wpinstall"/wp-config.php | grep -v WP_CACHE_KEY_SALT | cut -d \' -f 4)
    rm -f "$wpinstall$dbname".sql.gz
done
