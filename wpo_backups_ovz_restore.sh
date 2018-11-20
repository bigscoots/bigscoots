#!/bin/bash
# options
# h = human readable

BKUSER=wpo$(awk '{print $1}' /proc/vz/veinfo)
BKSVR=$(grep BKSVR= /bigscoots/wpo_backups_ovz.sh | sed 's/BKSVR=//g')

if [[ ! -f wp-config.php ]] ; then

 echo "Run this script within the public directory of the WP install, quiting..."
 exit

else

DOMAIN=$(echo "$(pwd)"| sed "s=/home/nginx/domains/==g ; s=/public==g")

fi

if ssh -i "$HOME"/.ssh/wpo_backups "$BKUSER"@"$BKSVR" 'uptime'; [ $? -eq 255 ]
then
  echo "Connection to backup server has failed."
  exit 1
fi

echo "Available Backups:"

if [[ $1 = h ]]

then

ssh -i "$HOME"/.ssh/wpo_backups "$BKUSER"@"$BKSVR" "ls -1d */$DOMAIN | sed 's/incomplete_back-/Incomplete Backup: /g ; s/back-/Full Backup: /g ; s/T/ /g ; s/_/:/g ; s/\/$DOMAIN//g'";

else

ssh -i "$HOME"/.ssh/wpo_backups "$BKUSER"@"$BKSVR" "ls -1d */$DOMAIN | sed 's/\/$DOMAIN//g'"

fi

echo
echo "Example rsync command - You should run a backup before proceeding"
echo "# rsync -ahv -e \"ssh -i $HOME/.ssh/wpo_backups\" --delete $BKUSER@$BKSVR:~/current/$DOMAIN/public/ $(pwd)/"
echo
