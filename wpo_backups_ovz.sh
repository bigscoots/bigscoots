#!/bin/bash

date=$(date "+%Y-%m-%dT%H_%M_%S")
HOMEDIR=/home/nginx/domains/
BKSVR=
BSPATH=/root/.bigscoots
PATH=/usr/lib64/ccache:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin:/root/bin
WPCLIFLAGS="--allow-root --skip-plugins --skip-themes --require=/bigscoots/includes/err_report.php"
BKLIMIT=30

mkdir -p "$BSPATH"
touch "$BSPATH"/backupinfo

if ! rpm -q jq >/dev/null 2>&1 ; then 
  yum -q -y install jq >/dev/null 2>&1
fi

if ! jq -Rn >/dev/null 2>&1; then
  wget -O /usr/bin/jq https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 >/dev/null 2>&1
  chmod +x /usr/bin/jq
fi 

if [ -f /etc/csf/csf.allow ] && ! grep -q 69.162.173.37 /etc/csf/csf.allow; then 
    csf -a 69.162.173.37 >/dev/null 2>&1
fi

if [ -f /etc/csf/csf.allow ] && ! grep -q 50.31.116.52 /etc/csf/csf.allow; then 
    csf -a 50.31.116.52 >/dev/null 2>&1
fi

if [ -f /etc/csf/csf.allow ] && ! grep -q 67.202.70.92 /etc/csf/csf.allow; then 
    csf -a 67.202.70.92 >/dev/null 2>&1
fi

if [ -f /etc/csf/csf.allow ] && ! grep -q 216.185.212.7 /etc/csf/csf.allow; then 
    csf -a 216.185.212.7 >/dev/null 2>&1
fi

if [ -f /etc/csf/csf.allow ] && ! grep -q 216.185.212.8 /etc/csf/csf.allow; then 
    csf -a 216.185.212.8 >/dev/null 2>&1
fi

if [ ! -f "$BSPATH"/rsync/exclude ]; then
  mkdir -p "$BSPATH"/rsync

  {
  echo ".infected_*"
  echo "log/access.log*"
  echo "log/error.log*"
  echo "*/core.[0-9]*"
  echo "*/error_log"
  echo "debug.log"
  echo "*/wp-content/updraft"
  echo "*/wp-content/cache"
  echo "*/wp-content/wpbackitup_backups"
  echo "*/wp-content/uploads/ithemes-security"
  echo "*/wp-content/uploads/wpallimport"
  echo "*/wp-content/uploads/ShortpixelBackups"
  echo "backupbuddy_backups"
  echo "*/wp-content/backupwordpress-*-backups"
  echo "*/wp-content/backups-dup-pro"
  } > "$BSPATH"/rsync/exclude

fi

if grep bksvr "$BSPATH"/backupinfo >/dev/null 2>&1 ; then
  BKSVR=$(grep bksvr "$BSPATH"/backupinfo | sed 's/bksvr=//g')
fi

if ! grep -q destination=local /root/.bigscoots/backupinfo >/dev/null 2>&1; then
  if [ -f /proc/vz/veinfo ] && ! grep -q destination=local /root/.bigscoots/backupinfo >/dev/null 2>&1; then
    remote=y
    if grep -q bkuser= "${BSPATH}"/backupinfo; then 
      BKUSER=$(grep bkuser= "${BSPATH}"/backupinfo | sed 's/=/ /g' | awk '{print $2}')
    else
      BKUSER=wpo$(awk '{print $1}' /proc/vz/veinfo)
    fi
  elif ! grep -qs '/backup ' /proc/mounts && ! grep destination=remote "$BSPATH"/backupinfo >/dev/null 2>&1 ; then
    echo "Make sure to set destination=remote in ${BSPATH}/backupinfo if supposed to be remote backups." | mail -s "Backup drive not mounted in $HOSTNAME" monitor@bigscoots.com
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
fi

if ! grep -q bkuser= "${BSPATH}"/backupinfo; then 
  echo bkuser=${BKUSER} >> "${BSPATH}"/backupinfo
fi

if  [[ $remote == y ]] && [[ ! $1 =~ (initial_*|download) ]]; then
  SSHOPTIONS="ssh -oStrictHostKeyChecking=no -i $HOME/.ssh/wpo_backups"
  RSYNCLOCATION="$BKUSER@$BKSVR:"

  # Try the backup server that is already defined
  if ! ssh -oBatchMode=yes -oStrictHostKeyChecking=no -i "$HOME"/.ssh/wpo_backups "$BKUSER"@"$BKSVR" 'exit' >/dev/null 2>&1; then
    # If there are no domains that means initial backup was never ran yet so connectin is going to fail, so just exit and initialize from wpo. 
    if [ ! "$(ls -A /home/nginx/domains)" ]; then
      exit
    fi
    # SSH connection failed, will open up a support task in WPO.
    WPOIP=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1')
    curl -s -d "email=${WPOIP}&domain=${HOSTNAME}&type=Backup%20Failure" -X POST https://api-dev.bigscoots.com/alerts/generate-support-task
    exit 1
  fi
else
  # If this is not a remote backup then well just set the backup location to the local backup drive.
  RSYNCLOCATION=/backup/
fi

case $1 in
manual)

  if [[ $2 == manual-* ]]; then

  dbname=$(wp $WPCLIFLAGS config get DB_NAME)
  mysqldump -f "$dbname"  > "$dbname".sql 2>database.err
  if [ "$?" -eq 0 ]; then
    gzip -f "$wpinstall$dbname".sql >/dev/null 2>&1
  fi
  if [ "$?" -eq 3 ]; then
    mysqlcheck "$dbname" --auto-repair --check
    mysqldump -f "$dbname"  > "$dbname".sql 2>database.err
    if [ "$?" -eq 0 ]; then
      gzip -f "$wpinstall$dbname".sql >/dev/null 2>&1
    fi
      if [ "$?" -eq 3 ]; then
      cat database.err | mail -s "WPO Backup Failed - mysqldump error - mysqlcheck was attempted stil failed -  $dbname  $HOSTNAME" monitor@bigscoots.com
      fi
  fi

    if  [[ $remote == y ]]; then
      
      ssh -oStrictHostKeyChecking=no -i "${HOME}"/.ssh/wpo_backups "${BKUSER}"@"${BKSVR}" "[ ! -d current ] && ln -s .ssh current"

      rsync -ah \
      -e "${SSHOPTIONS}" \
      --ignore-errors \
      --delete \
      --delete-excluded \
      --exclude-from=/bigscoots/wpo/backups/rsync/exclude \
      --exclude-from="${BSPATH}"/rsync/exclude \
      --link-dest=../current \
      "$(dirname ${PWD})" "${RSYNCLOCATION}incomplete_back-${date}" 

      ssh -oStrictHostKeyChecking=no -i "${HOME}"/.ssh/wpo_backups "${BKUSER}"@"${BKSVR}" "mv incomplete_back-$date ${2} && rm -f current && ln -s ${2} current"

    else

      [ ! -d /backup/current ] && ln -s /bigscoots /backup/current

      rsync -ah \
      -e "$SSHOPTIONS" \
      --ignore-errors \
      --delete \
      --delete-excluded \
      --exclude-from=/bigscoots/wpo/backups/rsync/exclude \
      --exclude-from="$BSPATH"/rsync/exclude \
      --link-dest=../current \
      "$(dirname ${PWD})" "${RSYNCLOCATION}incomplete_back-${date}" 
      
      mv /backup/incomplete_back-"${date}" /backup/"${2}" && rm -f /backup/current && ln -s /backup/"${2}" /backup/current
    fi
    
  else

for wpinstall in $(find /home/nginx/domains/*/public/ -type f -name wp-config.php | sed 's/wp-config.php//g'); do
  dbname=$(wp $WPCLIFLAGS config get DB_NAME --path="$wpinstall")
  mysqldump -f "$dbname"  > "$wpinstall$dbname".sql 2>"$wpinstall"database.err

    if [ "$?" -eq 0 ]; then
      gzip -f "$wpinstall$dbname".sql >/dev/null 2>&1
    fi
    if [ "$?" -eq 3 ]; then
      mysqlcheck "$dbname" --auto-repair --check
      mysqldump -f "$dbname"  > "$wpinstall$dbname".sql 2>"$wpinstall"database.err
    if [ "$?" -eq 0 ]; then
      gzip -f "$wpinstall$dbname".sql >/dev/null 2>&1
    fi
      if [ "$?" -eq 3 ]; then
        cat "$wpinstall"database.err | mail -s "WPO Backup Failed - mysqldump error - mysqlcheck was attempted stil failed -   $dbname  $HOSTNAME" monitor@bigscoots.com
      fi
    fi

done

gzip -f "$wpinstall$dbname".sql >/dev/null 2>&1

    if  [[ $remote == y ]]; then

      ssh -oStrictHostKeyChecking=no -i "${HOME}"/.ssh/wpo_backups "${BKUSER}"@"${BKSVR}" "[ ! -d current ] && ln -s .ssh current"
      
      rsync -ah \
      -e "${SSHOPTIONS}" \
      --ignore-errors \
      --delete \
      --delete-excluded \
      --exclude-from=/bigscoots/wpo/backups/rsync/exclude \
      --exclude-from="${BSPATH}"/rsync/exclude \
      --link-dest=../current \
      "${HOMEDIR}" "${RSYNCLOCATION}incomplete_back-${date}" 

      ssh -oStrictHostKeyChecking=no -i "${HOME}"/.ssh/wpo_backups "${BKUSER}"@"${BKSVR}" "mv incomplete_back-$date manual-${date} && rm -f current && ln -s manual-${date} current"

    else

      [ ! -d /backup/current ] && ln -s /bigscoots /backup/current
      
      rsync -ah \
      -e "$SSHOPTIONS" \
      --ignore-errors \
      --delete \
      --delete-excluded \
      --exclude-from=/bigscoots/wpo/backups/rsync/exclude \
      --exclude-from="$BSPATH"/rsync/exclude \
      --link-dest=../current \
      "${HOMEDIR}" "${RSYNCLOCATION}incomplete_back-${date}" 
      
      mv /backup/incomplete_back-"${date}" /backup/back-"${date}" && rm -f /backup/current && ln -s /backup/"manual-${date}" /backup/current
    fi
  fi

;;
delete)

  if [[ -z $2 ]]; then

      echo "Make sure to specify a manual backup folder name."
      exit
  fi

  if [[ $2 == manual-* ]]; then

    if  [[ $remote == y ]]; then

      mkdir -p "$HOMEDIR"/.empty
      rsync -a \
      -e "$SSHOPTIONS" \
      --ignore-errors \
      --ignore-missing-args \
      --delete \
      "$HOMEDIR"/.empty/ "$BKUSER"@"$BKSVR":"$2"/"$(dirname "$PWD" | sed 's/\// /g' | awk '{print $4}')"

      ssh -oStrictHostKeyChecking=no -i "$HOME"/.ssh/wpo_backups "$BKUSER"@"$BKSVR" "rmdir -p $2/$(dirname "$PWD" | sed 's/\// /g' | awk '{print $4}')"

    else

      mkdir -p "$HOMEDIR"/.empty
      rsync -a \
      --ignore-errors \
      --ignore-missing-args \
      --delete \
      "$HOMEDIR"/.empty/ /backup/"$2"/"$(dirname $PWD | sed 's/\// /g' | awk '{print $4}')"

      rm -rf "/backup/$2"

    fi

fi

;;
initial_client)

if crontab -l | grep /bigscoots/wpo_backups_dedi.sh >/dev/null 2>&1; then 
  crontab -l | grep -v 'wpo_backups_dedi.sh'  | crontab -
fi

if ! crontab -l | grep /bigscoots/wpo_backups_ovz.sh >/dev/null 2>&1; then 
  crontab -l | { cat; echo "$(( ( RANDOM % 60 )  + 1 )) $(( ( RANDOM % 4 )  + 1 )) * * * /bigscoots/wpo_backups_ovz.sh"; } | crontab -
fi

if ! grep -q bksvr "${BSPATH}"/backupinfo >/dev/null 2>&1 ; then
  BKSVR="$(shuf -e backup10.bigscoots.com backup11.bigscoots.com | head -1)"
  echo bksvr="${BKSVR}" >> "${BSPATH}"/backupinfo
fi

pushkey=false

if grep -q destination=local /root/.bigscoots/backupinfo >/dev/null 2>&1; then
  pubkey=null
  BKSVR=local
  BKUSER=/backup
else
  if [ ! -s ~/.ssh/wpo_backups ]; then
    ssh-keygen -b 4096 -t rsa -f ~/.ssh/wpo_backups -q -N '' <<< y >/dev/null 2>&1
  fi
  if ! ssh -q -o BatchMode=yes -o StrictHostKeyChecking=no -o PasswordAuthentication=no -i "$HOME"/.ssh/wpo_backups "$BKUSER"@"$BKSVR" exit; then
    ssh-keygen -b 4096 -t rsa -f ~/.ssh/wpo_backups -q -N '' <<< y >/dev/null 2>&1
    pushkey=true
  fi
  if [ ! -s ~/.ssh/wpo_backups.pub ]; then
    pubkey=null
  else
    pubkey=$(awk '{print $2}' /root/.ssh/wpo_backups.pub)
  fi
fi


backupinfo="runSecondScript|sshpubkey|backupserver|backupuser|backuplimit
$pushkey|$pubkey|$BKSVR|$BKUSER|$BKLIMIT"

  jq -Rn '
( input  | split("|") ) as $keys |
( inputs | split("|") ) as $vals |
[[$keys, $vals] | transpose[] | {key:.[0],value:.[1]}] | from_entries
' <<<"$backupinfo"

;;
initial_server)

BKUSER="$2"
SSHPUBKEY="$3"

if ! adduser -b /home/wpo_users "$BKUSER" >/dev/null 2>&1; then
  if [ ! -d /home/wpo_users/"$BKUSER" ]; then
    userdel -r "$BKUSER" >/dev/null 2>&1
  fi
fi

runuser -l "$BKUSER" -c 'ssh-keygen -b 4096 -t rsa -f ~/.ssh/id_rsa -q -N "" <<< y >/dev/null 2>&1 ; touch ~/.ssh/authorized_keys ; chmod 600 ~/.ssh/authorized_keys'
echo "ssh-rsa $SSHPUBKEY" >> /home/wpo_users/"$BKUSER"/.ssh/authorized_keys

;;
download)

BKUSER="$2"
DOMAIN="$3"
BACKUP="$4"

if [[ ${BKUSER} = '/backup' ]]; then
  if ! cd /backup/"$BACKUP" ; then 
    echo "Tried to cd into /backup/$BACKUP on  $HOSTNAME but failed during creating a backup for $DOMAIN" | mail -s "WPO - Local download backup failed on  $HOSTNAME check ticket message" monitor@bigscoots.com
    exit 
  fi
  tar --warning=no-file-changed -zcf "$DOMAIN"-"$BACKUP".tar.gz "$DOMAIN"
  bash /bigscoots/wpo/backups/backup_link.sh "$DOMAIN"-"$BACKUP".tar.gz local
else
  if ! cd /home/wpo_users/"$BKUSER"/"$BACKUP"; then 
    echo "Tried to cd into /home/wpo_users/$BKUSER/$BACKUP on  $HOSTNAME but failed during creating a backup for $DOMAIN" | mail -s "WPO - Download backup failed on  $HOSTNAME check ticket message" monitor@bigscoots.com
    exit
  fi
  tar --warning=no-file-changed -zcf "$DOMAIN"-"$BACKUP".tar.gz "$DOMAIN"
  bash /bigscoots/wpo/backups/backup_link.sh "$DOMAIN"-"$BACKUP".tar.gz
fi

;;
*)

for wpinstall in $(find /home/nginx/domains/*/public/ -type f -name wp-config.php | sed 's/wp-config.php//g'); do
  dbname=$(wp $WPCLIFLAGS config get DB_NAME --path="$wpinstall")
  mysqldump -f "$dbname"  > "$wpinstall$dbname".sql 2>"$wpinstall"database.err
    if [ "$?" -eq 0 ]; then
      gzip -f "$wpinstall$dbname".sql >/dev/null 2>&1
    fi
    if [ "$?" -eq 3 ]; then
      mysqlcheck "$dbname" --auto-repair --check
      mysqldump -f "$dbname"  > "$wpinstall$dbname".sql 2>"$wpinstall"database.err
      if [ "$?" -eq 0 ]; then
      gzip -f "$wpinstall$dbname".sql >/dev/null 2>&1
      fi
      if [ "$?" -eq 3 ]; then
        cat "$wpinstall"database.err | mail -s "WPO Backup Failed - mysqldump error - mysqlcheck was attempted stil failed -   $dbname  $HOSTNAME" monitor@bigscoots.com
      fi
    fi

done

gzip -f "$wpinstall$dbname".sql >/dev/null 2>&1

    if  [[ $remote == y ]]; then

      ssh -oStrictHostKeyChecking=no -i "${HOME}"/.ssh/wpo_backups "${BKUSER}"@"${BKSVR}" "[ ! -d current ] && ln -s .ssh current"
      
      rsync -ah \
      -e "${SSHOPTIONS}" \
      --ignore-errors \
      --delete \
      --delete-excluded \
      --exclude-from=/bigscoots/wpo/backups/rsync/exclude \
      --exclude-from="${BSPATH}"/rsync/exclude \
      --link-dest=../current \
      "${HOMEDIR}" "${RSYNCLOCATION}incomplete_back-${date}" 

      ssh -oStrictHostKeyChecking=no -i "${HOME}"/.ssh/wpo_backups "${BKUSER}"@"${BKSVR}" "mv incomplete_back-$date back-${date} && rm -f current && ln -s back-${date} current"

    else

      [ ! -d /backup/current ] && ln -s /bigscoots /backup/current
      
      rsync -ah \
      -e "$SSHOPTIONS" \
      --ignore-errors \
      --delete \
      --delete-excluded \
      --exclude-from=/bigscoots/wpo/backups/rsync/exclude \
      --exclude-from="$BSPATH"/rsync/exclude \
      --link-dest=../current \
      "${HOMEDIR}" "${RSYNCLOCATION}incomplete_back-${date}" 
      
      mv /backup/incomplete_back-"${date}" /backup/back-"${date}" && rm -f /backup/current && ln -s /backup/back-"${date}" /backup/current
    fi

;;
esac

if [[ ! $1 =~ (initial_*|download) ]]; then

for wpinstall in $(find /home/nginx/domains/*/public/ -type f -name wp-config.php | sed 's/wp-config.php//g')
   do
    if wp $WPCLIFLAGS config get DB_NAME --path="$wpinstall" > /dev/null 2>&1 ; then 
      dbname=$(wp $WPCLIFLAGS config get DB_NAME --path="$wpinstall")
      rm -f "$wpinstall$dbname".sql "$wpinstall$dbname".sql.gz "$wpinstall"database.err
    fi
done

fi
