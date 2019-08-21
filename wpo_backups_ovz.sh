#!/bin/bash

date=$(date "+%Y-%m-%dT%H_%M_%S")
HOMEDIR=/home/nginx/domains/
BKSVR=backup3.bigscoots.com
BSPATH=/root/.bigscoots
PATH=/usr/lib64/ccache:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin:/root/bin
WPCLIFLAGS="--allow-root --skip-plugins --skip-themes"

if [ ! -f "$BSPATH"/rsync/exclude ]; then
  mkdir -p "$BSPATH"/rsync

  {
  echo ".infected_*"
  echo "log/access.log*"
  echo "log/error.log*"
  echo "*/core.[0-9]*"
  echo "*/error_log"
  echo "*/wp-content/updraft"
  echo "*/wp-content/cache"
  echo "*/wp-content/wpbackitup_backups"
  echo "*/wp-content/uploads/ithemes-security"
  echo "*/wp-content/uploads/wpallimport"
  echo "*/wp-content/uploads/ShortpixelBackups"
  } > "$BSPATH"/rsync/exclude

fi

if [ -f /proc/vz/veinfo ]; then
  remote=y
  BKUSER=wpo$(awk '{print $1}' /proc/vz/veinfo)
elif ! grep -qs '/backup ' /proc/mounts && ! grep destination=remote "$BSPATH"/backupinfo > /dev/null ; then
  echo "Make sure to set destination=remote in "${BSPATH}"/backupinfo if supposed to be remote backups." | mail -s "Backup drive not mounted in $HOSTNAME" monitor@bigscoots.com
  remote=y
  BKUSER=wpo"${HOSTNAME//./}"
elif ! grep -qs '/backup ' /proc/mounts && grep destination=remote "$BSPATH"/backupinfo > /dev/null ; then
  remote=y
  if [[ -n $(grep bkuser= "${BSPATH}"/backupinfo | sed 's/=/ /g' | awk '{print $2}') ]]; then
    BKUSER=$(grep bkuser= "${BSPATH}"/backupinfo | sed 's/=/ /g' | awk '{print $2}')
  else
    BKUSER=wpo"${HOSTNAME//./}"
  fi

fi

if  [[ $remote == y ]]; then
  SSHOPTIONS="ssh -oStrictHostKeyChecking=no -i $HOME/.ssh/wpo_backups"
  RSYNCLOCATION="$BKUSER@$BKSVR:"
  if ssh -oStrictHostKeyChecking=no -i "$HOME"/.ssh/wpo_backups "$BKUSER"@"$BKSVR" 'uptime' >/dev/null; [ $? -eq 255 ]
  then
    echo "Mark for Justin" | mail -s "$HOSTNAME- WPO failed to SSH to backup server." monitor@bigscoots.com
    exit 1
  fi
else
  RSYNCLOCATION=/backup/
fi

case $1 in
manual)

  if [[ $2 == manual-* ]]; then

  dbname=$(wp $WPCLIFLAGS config get DB_NAME)
  /usr/bin/mysqldump "$dbname" | gzip > "$dbname".sql.gz

    if  [[ $remote == y ]]; then
      
      rsync -ah \
      -e "${SSHOPTIONS}" \
      --ignore-errors \
      --delete \
      --delete-excluded \
      --exclude-from="${BSPATH}"/rsync/exclude \
      --link-dest=../current \
      "$(dirname ${PWD})" "${RSYNCLOCATION}incomplete_back-${date}" 

      ssh -oStrictHostKeyChecking=no -i "${HOME}"/.ssh/wpo_backups "${BKUSER}"@"${BKSVR}" "mv incomplete_back-$date ${2} && rm -f current && ln -s ${2} current"

    else

      rsync -ah \
      -e "$SSHOPTIONS" \
      --ignore-errors \
      --delete \
      --delete-excluded \
      --exclude-from="$BSPATH"/rsync/exclude \
      --link-dest=../current \
      "$(dirname ${PWD})" "${RSYNCLOCATION}incomplete_back-${date}" 
      
      mv /backup/incomplete_back-"${date}" /backup/"${2}" && rm -f /backup/current && ln -s /backup/"${2}" /backup/current
    fi
    
  else

  for wpinstall in $(find /home/nginx/domains/*/public/ -type f -name wp-config.php | sed 's/wp-config.php//g')
   do
    dbname=$(wp $WPCLIFLAGS config get DB_NAME --path="$wpinstall")
    /usr/bin/mysqldump "$dbname" | gzip > "$wpinstall$dbname".sql.gz
  done

    if  [[ $remote == y ]]; then
      
      rsync -ah \
      -e "${SSHOPTIONS}" \
      --ignore-errors \
      --delete \
      --delete-excluded \
      --exclude-from="${BSPATH}"/rsync/exclude \
      --link-dest=../current \
      "${HOMEDIR}" "${RSYNCLOCATION}incomplete_back-${date}" 

      ssh -oStrictHostKeyChecking=no -i "${HOME}"/.ssh/wpo_backups "${BKUSER}"@"${BKSVR}" "mv incomplete_back-$date manual-${date} && rm -f current && ln -s manual-${date} current"

    else
      
      rsync -ah \
      -e "$SSHOPTIONS" \
      --ignore-errors \
      --delete \
      --delete-excluded \
      --exclude-from="$BSPATH"/rsync/exclude \
      --link-dest=../current \
      "${HOMEDIR}" "${RSYNCLOCATION}incomplete_back-${date}" 
      
      mv /backup/incomplete_back-"${date}" /backup/back-"${date}" && rm -f /backup/current && ln -s /backup/"manual-${date}" /backup/current
    fi
  fi

;;
delete)

  if [[ $2 == manual-* ]]; then

 mkdir -p "$HOMEDIR"/.empty
 rsync -a \
 -e "$SSHOPTIONS" \
 --ignore-errors \
 --delete \
 "$HOMEDIR"/.empty/ "$BKUSER"@"$BKSVR":"$2"/"$(dirname "$PWD" | sed 's/\// /g' | awk '{print $4}')"

 ssh -oStrictHostKeyChecking=no -i "$HOME"/.ssh/wpo_backups "$BKUSER"@"$BKSVR" "rmdir -p $2/$(dirname "$PWD" | sed 's/\// /g' | awk '{print $4}')"


else

  echo "Make sure to specify a manual backup folder name."

fi

;;
*)

for wpinstall in $(find /home/nginx/domains/*/public/ -type f -name wp-config.php | sed 's/wp-config.php//g')
   do
    dbname=$(wp $WPCLIFLAGS config get DB_NAME --path="$wpinstall")
    /usr/bin/mysqldump "$dbname" | gzip > "$wpinstall$dbname".sql.gz
done

    if  [[ $remote == y ]]; then
      
      rsync -ah \
      -e "${SSHOPTIONS}" \
      --ignore-errors \
      --delete \
      --delete-excluded \
      --exclude-from="${BSPATH}"/rsync/exclude \
      --link-dest=../current \
      "${HOMEDIR}" "${RSYNCLOCATION}incomplete_back-${date}" 

      ssh -oStrictHostKeyChecking=no -i "${HOME}"/.ssh/wpo_backups "${BKUSER}"@"${BKSVR}" "mv incomplete_back-$date back-${date} && rm -f current && ln -s back-${date} current"

    else
      
      rsync -ah \
      -e "$SSHOPTIONS" \
      --ignore-errors \
      --delete \
      --delete-excluded \
      --exclude-from="$BSPATH"/rsync/exclude \
      --link-dest=../current \
      "${HOMEDIR}" "${RSYNCLOCATION}incomplete_back-${date}" 
      
      mv /backup/incomplete_back-"${date}" /backup/back-"${date}" && rm -f /backup/current && ln -s /backup/back-"${date}" /backup/current
    fi

;;
esac

for wpinstall in $(find /home/nginx/domains/*/public/ -type f -name wp-config.php | sed 's/wp-config.php//g')
   do
    dbname=$(wp $WPCLIFLAGS config get DB_NAME --path="$wpinstall")
    rm -f "$wpinstall$dbname".sql.gz
done