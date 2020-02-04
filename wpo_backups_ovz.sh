#!/bin/bash

date=$(date "+%Y-%m-%dT%H_%M_%S")
HOMEDIR=/home/nginx/domains/
BKSVR=backup3.bigscoots.com
BSPATH=/root/.bigscoots
PATH=/usr/lib64/ccache:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin:/root/bin
WPCLIFLAGS="--allow-root --skip-plugins --skip-themes --require=/bigscoots/includes/err_report.php"
BKLIMIT=30

mkdir -p "$BSPATH"
touch "$BSPATH"/backupinfo

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

if grep bksvr "$BSPATH"/backupinfo >/dev/null 2>&1 ; then
  BKSVR=$(grep bksvr "$BSPATH"/backupinfo | sed 's/bksvr=//g')
fi

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

if  [[ $remote == y ]] && [[ $1 != initial_* ]]; then
  SSHOPTIONS="ssh -oStrictHostKeyChecking=no -i $HOME/.ssh/wpo_backups"
  RSYNCLOCATION="$BKUSER@$BKSVR:"
  if ssh -oBatchMode=yes -oStrictHostKeyChecking=no -i "$HOME"/.ssh/wpo_backups "$BKUSER"@"$BKSVR" 'uptime' >/dev/null 2>&1 ; [ $? -eq 255 ]
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
  mysqldump "$dbname"  > "$dbname".sql 2>database.err
  if [ "$?" -eq 0 ]; then
    gzip "$wpinstall$dbname".sql >/dev/null 2>&1
  fi
  if [ "$?" -eq 3 ]; then
    mysqlcheck "$dbname" --auto-repair --check
    mysqldump "$dbname"  > "$dbname".sql 2>database.err
    if [ "$?" -eq 0 ]; then
      gzip "$wpinstall$dbname".sql >/dev/null 2>&1
    fi
      if [ "$?" -eq 3 ]; then
      cat database.err | mail -s "WPO Backup Failed - mysqldump error - mysqlcheck was attempted stil failed -  $dbname  $HOSTNAME" monitor@bigscoots.com
      fi
  fi

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

for wpinstall in $(find /home/nginx/domains/*/public/ -type f -name wp-config.php | sed 's/wp-config.php//g'); do
  dbname=$(wp $WPCLIFLAGS config get DB_NAME --path="$wpinstall")
  mysqldump "$dbname"  > "$wpinstall$dbname".sql 2>"$wpinstall"database.err

    if [ "$?" -eq 0 ]; then
      gzip "$wpinstall$dbname".sql >/dev/null 2>&1
    fi
    if [ "$?" -eq 3 ]; then
      mysqlcheck "$dbname" --auto-repair --check
      mysqldump "$dbname"  > "$wpinstall$dbname".sql 2>"$wpinstall"database.err
    if [ "$?" -eq 0 ]; then
      gzip "$wpinstall$dbname".sql >/dev/null 2>&1
    fi
      if [ "$?" -eq 3 ]; then
        cat "$wpinstall"database.err | mail -s "WPO Backup Failed - mysqldump error - mysqlcheck was attempted stil failed -   $dbname  $HOSTNAME" monitor@bigscoots.com
      fi
    fi

done

gzip "$wpinstall$dbname".sql >/dev/null 2>&1

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
      --delete \
      "$HOMEDIR"/.empty/ "$BKUSER"@"$BKSVR":"$2"/"$(dirname "$PWD" | sed 's/\// /g' | awk '{print $4}')"

      ssh -oStrictHostKeyChecking=no -i "$HOME"/.ssh/wpo_backups "$BKUSER"@"$BKSVR" "rmdir -p $2/$(dirname "$PWD" | sed 's/\// /g' | awk '{print $4}')"

    else

      mkdir -p "$HOMEDIR"/.empty
      rsync -a \
      --ignore-errors \
      --delete \
      "$HOMEDIR"/.empty/ /backup/"$2"/"$(dirname $PWD | sed 's/\// /g' | awk '{print $4}')"

      rm -rf "/backup/$2"

    fi

fi

;;
initial_client)

push=false

if ! rpm -q jq >/dev/null 2>&1 ; then 
  yum -q -y install jq
fi

if [ ! -s ~/.ssh/wpo_backups ]; then
  ssh-keygen -b 4096 -t rsa -f ~/.ssh/wpo_backups -q -N '' <<< y >/dev/null 2>&1
fi

if ! ssh -q -o BatchMode=yes -o StrictHostKeyChecking=no -o PasswordAuthentication=no -i "$HOME"/.ssh/wpo_backups "$BKUSER"@$BKSVR exit; then
    ssh-keygen -b 4096 -t rsa -f ~/.ssh/wpo_backups -q -N '' <<< y >/dev/null 2>&1
    pushkey=true
fi

backupinfo="runSecondScript|sshpubkey|backupserver|backupuser|backuplimit
$pushkey|$(awk '{print $2}' /root/.ssh/wpo_backups.pub)|$BKSVR|$BKUSER|$BKLIMIT"

  jq -Rn '
( input  | split("|") ) as $keys |
( inputs | split("|") ) as $vals |
[[$keys, $vals] | transpose[] | {key:.[0],value:.[1]}] | from_entries
' <<<"$backupinfo"

;;
initial_server)

BKUSER="$1"
SSHPUBKEY="$2"

adduser -b /home/wpo_users "$BKUSER"
runuser -l "$BKUSER" -c 'ssh-keygen -b 4096 -t rsa -f ~/.ssh/id_rsa -q -N "" <<< y >/dev/null 2>&1 ; touch ~/.ssh/authorized_keys ; chmod 600 ~/.ssh/authorized_keys'
echo "ssh-rsa $SSHPUBKEY" >> /home/wpo_users/"$BKUSER"/.ssh/authorized_keys

;;
*)

for wpinstall in $(find /home/nginx/domains/*/public/ -type f -name wp-config.php | sed 's/wp-config.php//g'); do
  dbname=$(wp $WPCLIFLAGS config get DB_NAME --path="$wpinstall")
  mysqldump "$dbname"  > "$wpinstall$dbname".sql 2>"$wpinstall"database.err
    if [ "$?" -eq 0 ]; then
      gzip "$wpinstall$dbname".sql >/dev/null 2>&1
    fi
    if [ "$?" -eq 3 ]; then
      mysqlcheck "$dbname" --auto-repair --check
      mysqldump "$dbname"  > "$wpinstall$dbname".sql 2>"$wpinstall"database.err
      if [ "$?" -eq 0 ]; then
      gzip "$wpinstall$dbname".sql >/dev/null 2>&1
      fi
      if [ "$?" -eq 3 ]; then
        cat "$wpinstall"database.err | mail -s "WPO Backup Failed - mysqldump error - mysqlcheck was attempted stil failed -   $dbname  $HOSTNAME" monitor@bigscoots.com
      fi
    fi

done

gzip "$wpinstall$dbname".sql >/dev/null 2>&1

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

if [[ $1 != initial_* ]]; then

for wpinstall in $(find /home/nginx/domains/*/public/ -type f -name wp-config.php | sed 's/wp-config.php//g')
   do
    dbname=$(wp $WPCLIFLAGS config get DB_NAME --path="$wpinstall")
    rm -f "$wpinstall$dbname".sql "$wpinstall$dbname".sql.gz "$wpinstall"database.err
done

fi