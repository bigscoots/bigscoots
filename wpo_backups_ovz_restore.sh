#!/bin/bash
# options
# h = human readable

date=$(date "+%Y-%m-%dT%H_%M_%S")
HOMEDIR=/home/nginx/domains/
BKSVR=backup3.bigscoots.com
BSPATH=/root/.bigscoots
PATH=/usr/lib64/ccache:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin:/root/bin
WPCLIFLAGS="--allow-root --skip-plugins --skip-themes --require=/bigscoots/includes/err_report.php"
BKLIMIT=30

if grep bksvr "$BSPATH"/backupinfo >/dev/null 2>&1 ; then
  BKSVR=$(grep bksvr "$BSPATH"/backupinfo | sed 's/bksvr=//g')
fi

if [ -f /proc/vz/veinfo ]; then
  remote=y
  if grep -q bkuser= "${BSPATH}"/backupinfo; then
    BKUSER=$(grep bkuser= "${BSPATH}"/backupinfo | sed 's/=/ /g' | awk '{print $2}')
  else
  BKUSER=wpo$(awk '{print $1}' /proc/vz/veinfo)
  fi
elif ! grep -qs '/backup ' /proc/mounts && ! grep destination=remote "$BSPATH"/backupinfo >/dev/null 2>&1 ; then
  echo "Make sure to set destination=remote in "${BSPATH}"/backupinfo if supposed to be remote backups." | mail -s "Backup drive not mounted in $HOSTNAME" monitor@bigscoots.com
  remote=y
  BKUSER=wpo"${HOSTNAME//./}"
elif ! grep -qs '/backup ' /proc/mounts && grep destination=remote "$BSPATH"/backupinfo >/dev/null 2>&1 ; then
  remote=y
  if [[ -n $(grep bkuser= "${BSPATH}"/backupinfo | sed 's/=/ /g' | awk '{print $2}') ]]; then
    BKUSER=$(grep bkuser= "${BSPATH}"/backupinfo | sed 's/=/ /g' | awk '{print $2}')
  else
    BKUSER=wpo"${HOSTNAME//./}"
  fi
fi


if [ -f /proc/vz/veinfo ] || grep -q destination=remote "$BSPATH"/backupinfo ;
then

# BKUSER=wpo$(awk '{print $1}' /proc/vz/veinfo)

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

# h - used for listing available backups in format for WPO panel
# /bigscoots/wpo_backups_ovz_restore.sh h [daily/manual]

case $1 in
h)

if [ -z "$2" ]; then

 echo "/bigscoots/wpo_backups_ovz_restore.sh h [daily/manual] required"
 exit

fi

# /bigscoots/wpo_backups_ovz_restore.sh h daily
# This will list out backups in WPO panel format for daily backups

if [ $2 = "daily" ]; then

ssh -i "$HOME"/.ssh/wpo_backups "$BKUSER"@"$BKSVR" "ls -1d */$DOMAIN | sed 's/incomplete_back-//g ; s/back-//g ; s/T/ /g ; s/_/:/g ; s/\/$DOMAIN//g' | grep -v 'current\|manual' | sed 's/$/;/g'"

# /bigscoots/wpo_backups_ovz_restore.sh h manual
# This will list out backups in WPO panel format for manual backups

elif [ $2 = "manual" ]; then

ssh -i "$HOME"/.ssh/wpo_backups "$BKUSER"@"$BKSVR" "ls -1d */$DOMAIN | sed 's/incomplete_back-//g ; s/back-//g ; s/T/ /g ; s/_/:/g ; s/\/$DOMAIN//g' | grep 'manual' | sed 's/manual-//g' | sed 's/$/;/g'"

fi

# /bigscoots/wpo_backups_ovz_restore.sh hh 
# this will list out all backups for the current wordpress install, must be in the public directory.

;;
hh)

ssh -i "$HOME"/.ssh/wpo_backups "$BKUSER"@"$BKSVR" "ls -1d */$DOMAIN | sed 's/\/$DOMAIN//g' |grep -v current"

echo
echo "Example rsync command - You should run a backup before proceeding"
echo "# rsync -ahv -e \"ssh -i $HOME/.ssh/wpo_backups\" --delete $BKUSER@$BKSVR:$(ssh -i $HOME/.ssh/wpo_backups $BKUSER@$BKSVR 'echo $HOME')/$(ssh -i $HOME/.ssh/wpo_backups $BKUSER@$BKSVR "ls -1d */$DOMAIN | sed 's/\/$DOMAIN//g' |grep -v current" | tail -1)/$DOMAIN/public/ $(pwd)/"
echo

# /bigscoots/wpo_backups_ovz_restore.sh restore ${BACKUP}
# This will restore the current site from the date specified, must be in the public directory.
# Backup name example: back-2019-06-11T02_18_01

;;
restore)

{

dbname=$(wp ${WPCLIFLAGS} config get DB_NAME)

# "Restoring files..."

if ssh -i "$HOME"/.ssh/wpo_backups "$BKUSER"@"$BKSVR" "[ ! -d "~/"$2"/"$DOMAIN"/public" ]"
then
        exit
fi

rsync -ah -e "ssh -i $HOME/.ssh/wpo_backups" --delete "$BKUSER"@"$BKSVR":~/"$2"/"$DOMAIN"/public/ "$(pwd)"/

sed -i '/@include "/d' *.php


# "Backing up the current database..."

mysqldump "$dbname" | gzip > ../"$dbname".sql.gz

# "Dropping current database..."

mysqladmin -s drop -f "$dbname"


# "Restoring backup database..."

mysqladmin create "$dbname"

if [ -f "$dbname".sql.gz ]; then
    gunzip -f "$dbname".sql.gz
fi

mysql "$dbname" < "$dbname".sql
rm -f "$dbname".sql


# "Checking if Cloudflare plugin exists, reinstalling if so."


# "Setting proper permissions..."

chown -R nginx: $(pwd)
find $(pwd) -type f -exec chmod 644 {} \; &
find $(pwd) -type d -exec chmod 755 {} \; &


# "Restore has been completed!"

} 2>&1>/dev/null

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
if ! grep -qs '/backup ' /proc/mounts && ! grep destination=remote "$BSPATH"/backupinfo >/dev/null 2>&1 ; then
# if ! grep -qs '/backup ' /proc/mounts ; then
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

dbname=$(wp ${WPCLIFLAGS} config get DB_NAME)

# "Restoring files..."

if [ ! -d "/backup/"$2"/"$DOMAIN"/public" ] 
then
    exit
fi 

rsync -ah --delete /backup/"$2"/"$DOMAIN"/public/ "$(pwd)"/

sed -i '/@include "/d' *.php


# "Backing up the current database..."

mysqldump "$dbname" | gzip > ../"$dbname".sql.gz


# echo "Dropping current database..."

mysqladmin -s drop -f "$dbname"


# echo "Restoring backup database..."

mysqladmin create "$dbname"

if [ -f "$dbname".sql.gz ]; then
    gunzip -f "$dbname".sql.gz
fi

mysql "$dbname" < "$dbname".sql
rm -f "$dbname".sql

# "Setting proper permissions..."

chown -R nginx: $(pwd)
find $(pwd) -type f -exec chmod 644 {} \; &
find $(pwd) -type d -exec chmod 755 {} \; &

# "Restore has been completed!"

;;
*)
echo don\'t know
;;
esac

fi
