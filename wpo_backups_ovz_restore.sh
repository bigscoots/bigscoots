#!/bin/bash
# options
# h = human readable

BKSVR=$(grep BKSVR= /bigscoots/wpo_backups_ovz.sh | sed 's/BKSVR=//g')
MYSQLADMIN=$(which mysqladmin)
GUNZIP=$(which gunzip)
GZIP=$(which gzip)
MYSQL=$(which mysql)
MYSQLDUMP=$(which mysqldump)
RSYNC=$(which rsync)
CHOWN=$(which chown)

if [ -f /proc/vz/veinfo ];
then

BKUSER=wpo$(awk '{print $1}' /proc/vz/veinfo)

if [[ ! -f wp-config.php ]] ; then

 echo "Run this script within the public directory of the WP install, quiting..."
 exit

else

DOMAIN=$(echo "$(pwd)"| sed "s=/home/nginx/domains/==g ; s=/public==g")

fi

if ssh -i "$HOME"/.ssh/wpo_backups "$BKUSER"@"$BKSVR" 'uptime' >/dev/null ; [ $? -eq 255 ]
then
  echo "Connection to backup server has failed."
  exit 1
fi

case $1 in
h)

if [ $2 = "daily" ]; then

ssh -i "$HOME"/.ssh/wpo_backups "$BKUSER"@"$BKSVR" "ls -1d */$DOMAIN | sed 's/incomplete_back-//g ; s/back-//g ; s/T/ /g ; s/_/:/g ; s/\/$DOMAIN//g' | grep -v 'current\|manual' | sed 's/$/;/g'"

elif [ $2 = "manual" ]; then

ssh -i "$HOME"/.ssh/wpo_backups "$BKUSER"@"$BKSVR" "ls -1d */$DOMAIN | sed 's/incomplete_back-//g ; s/back-//g ; s/T/ /g ; s/_/:/g ; s/\/$DOMAIN//g' | grep 'manual' | sed 's/manual-//g' | sed 's/$/;/g'"

fi

;;
hh)
ssh -i "$HOME"/.ssh/wpo_backups "$BKUSER"@"$BKSVR" "ls -1d */$DOMAIN | sed 's/\/$DOMAIN//g' |grep -v current"
echo
echo "Example rsync command - You should run a backup before proceeding"
echo "# rsync -ahv -e \"ssh -i $HOME/.ssh/wpo_backups\" --delete $BKUSER@$BKSVR:$(ssh -i $HOME/.ssh/wpo_backups $BKUSER@$BKSVR 'echo $HOME')/$(ssh -i $HOME/.ssh/wpo_backups $BKUSER@$BKSVR "ls -1d */$DOMAIN | sed 's/\/$DOMAIN//g' |grep -v current" | tail -1)/$DOMAIN/public/ $(pwd)/"
echo

;;
restore)
dbname=$(grep DB_NAME wp-config.php | grep -v WP_CACHE_KEY_SALT | cut -d \' -f 4)

echo "Restoring files..."

"$RSYNC" -ah --stats -e "ssh -i $HOME/.ssh/wpo_backups" --delete "$BKUSER"@"$BKSVR":~/"$2"/"$DOMAIN"/public/ "$(pwd)"/

echo
echo "Backing up the current database..."

"$MYSQLDUMP" "$dbname" | "$GZIP" > ../"$dbname".sql.gz

echo
echo "Dropping current database..."

"$MYSQLADMIN" -s drop -f "$dbname"

echo
echo "Restoring backup database..."

"$MYSQLADMIN" create "$dbname"
"$GUNZIP" -f "$dbname".sql.gz
"$MYSQL" "$dbname" < "$dbname".sql
rm -f "$dbname".sql

echo
echo "Checking if Cloudflare plugin exists, reinstalling if so."

if [ -d wp-content/plugins/cloudflare ]; then
  wp plugin delete cloudflare
  wp plugin install cloudflare
fi

echo
echo "Setting proper permissions..."

"$CHOWN" -R nginx: $(pwd)
find $(pwd) -type f -exec chmod 644 {} \; &
find $(pwd) -type d -exec chmod 755 {} \; &

echo
echo "Restore has been completed!"

;;
*)
echo don\'t know
;;
esac

else

if [[ ! -f wp-config.php ]] ; then

 echo "Run this script within the public directory of the WP install, quiting..."
 exit

else

DOMAIN=$(echo "$(pwd)"| sed "s=/home/nginx/domains/==g ; s=/public==g")

fi

if ! grep -qs '/backup ' /proc/mounts ; then
   echo "Backup drive not mounted in $HOSTNAME" | mail -s "Backup drive not mounted in $HOSTNAME" monitor@bigscoots.com
   exit
fi

case $1 in
h)

if [ $2 = "daily" ]; then

ls -1d /backup/*/"$DOMAIN" | sed 's/\/backup\///g' | sed "s/incomplete_back-//g ; s/back-//g ; s/T/ /g ; s/_/:/g ; s/\/$DOMAIN//g" | grep -v 'current\|manual' | sed 's/$/;/g'

elif [ $2 = "manual" ]; then

ls -1d /backup/*/"$DOMAIN" | sed 's/\/backup\///g' | sed "s/incomplete_back-//g ; s/back-//g ; s/T/ /g ; s/_/:/g ; s/\/$DOMAIN//g" | grep manual | sed 's/manual-//g' | sed 's/$/;/g'

fi

;;
hh)
ls -1d /backup/*/$DOMAIN | sed 's/\/$DOMAIN//g' |grep -v current
echo
echo "Example rsync command - You should run a backup before proceeding"
echo "# rsync -ahv --delete /backup/current/$DOMAIN/public/ $(pwd)/"
echo

;;
restore)
dbname=$(grep DB_NAME wp-config.php | grep -v WP_CACHE_KEY_SALT | cut -d \' -f 4)

echo "Restoring files..."

"$RSYNC" -ah --stats --delete /backup/"$2"/"$DOMAIN"/public/ "$(pwd)"/

echo
echo "Backing up the current database..."

"$MYSQLDUMP" "$dbname" | "$GZIP" > ../"$dbname".sql.gz

echo
echo "Dropping current database..."

"$MYSQLADMIN" -s drop -f "$dbname"

echo
echo "Restoring backup database..."

"$MYSQLADMIN" create "$dbname"
"$GUNZIP" -f "$dbname".sql.gz
"$MYSQL" "$dbname" < "$dbname".sql
rm -f "$dbname".sql

echo
echo "Checking if Cloudflare plugin exists, reinstalling if so."

if [ -d wp-content/plugins/cloudflare ]; then
  wp plugin delete cloudflare
  wp plugin install cloudflare
fi

echo
echo "Setting proper permissions..."

"$CHOWN" -R nginx: $(pwd)
find $(pwd) -type f -exec chmod 644 {} \; &
find $(pwd) -type d -exec chmod 755 {} \; &

echo
echo "Restore has been completed!"

;;
*)
echo don\'t know
;;
esac

fi
