#!/bin/bash
######################################################
# cmupdate
# written by George Liu (eva2000) centminmod.com
######################################################
# variables
#MAINDIR='/etc/centminmod'
CM_INSTALLDIR='/bigscoots'
#############
#if [ -f "${MAINDIR}/custom_config.inc" ]; then
    # default is at /etc/centminmod/custom_config.inc
#    source "${MAINDIR}/custom_config.inc"
#fi

# variables
#############
#branchname=123.09beta01
#DT=$(date +"%d%m%y-%H%M%S")
######################################################
# functions
#############
# set locale temporarily to english
# due to some non-english locale issues
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
export LC_CTYPE=en_US.UTF-8

fupdate() {
  if [[ -d "${CM_INSTALLDIR}/.git" ]]; then
#    if [[ "$(curl -sL https://github.com/centminmod/centminmod/raw/${branchname}/gitclean.txt)" = 'no' ]]; then
      cd "${CM_INSTALLDIR}"
      git stash
      git pull
    else
      rm -rf "${CM_INSTALLDIR}"
      cd /
      git clone https://github.com/jcatello/bigscoots
    fi
}

######################################################
fupdate
unset reload

 # WPO Specific checks

if [ -f /usr/local/src/centminmod/centmin.sh ] ; then 

  if [[ ! -f /etc/centminmod/email-primary.ini ]]; then
	 touch /etc/centminmod/email-primary.ini
	 echo "root" > /etc/centminmod/email-primary.ini
  fi

  if [[ ! -f /etc/centminmod/email-secondary.ini ]]; then
	 touch /etc/centminmod/email-secondary.ini
	 echo "root" > /etc/centminmod/email-secondary.ini
  fi

  if ! grep -q @ /etc/centminmod/email-primary.ini > /dev/null 2>&1 ; then
 	  echo "root" > /etc/centminmod/email-primary.ini
  fi

  if ! grep -q @ /etc/centminmod/email-secondary.ini > /dev/null 2>&1 ; then
 	  echo "root" > /etc/centminmod/email-secondary.ini
  fi

  if ! grep -q bigscoots-staging.com /root/.bigscoots/php/opcache-blacklist.txt > /dev/null 2>&1 ; then
 	  mkdir -p /root/.bigscoots/php/
	 echo '/home/nginx/domains/*.bigscoots-staging.com/public/*' >> /root/.bigscoots/php/opcache-blacklist.txt
  fi

  if ! grep ^opcache.revalidate_freq=0 /etc/centminmod/php.d/zendopcache.ini  >/dev/null 2>&1; then 
    sed -i '/^opcache.revalidate_freq/c\opcache.revalidate_freq=0' /etc/centminmod/php.d/zendopcache.ini
    reload=1
  fi

  if grep \;request_slowlog_timeout /usr/local/etc/php-fpm.conf >/dev/null 2>&1 ; then 
    sed -i '/;request_slowlog_timeout/c\request_slowlog_timeout = 20' /usr/local/etc/php-fpm.conf
    reload=1
  fi

  # no longer needed since wpo_update.sh will exists on all servers n ow.

  if crontab -l |grep /bigscoots/dedicated/updater.sh > /dev/null 2>&1; then 
    crontab -l | grep -v '/usr/bin/cmupdate'  | crontab -
  fi

  # Disable serving webp due to Cloudflare

  if [ -f /usr/local/nginx/conf/webp.conf ] && grep -q '".webp";' /usr/local/nginx/conf/webp.conf; then 
    sed -i 's/".webp";/"";/g' /usr/local/nginx/conf/webp.conf
    reload=1
  fi

  if [ ! -f /etc/centminmod/custom_config.inc ]; then
    mkdir -p /etc/centminmod/
    touch /etc/centminmod/custom_config.inc
  fi

  if ! grep -q ENABLEMOTD /etc/centminmod/custom_config.inc; then
    echo "ENABLEMOTD='n'" >> /etc/centminmod/custom_config.inc
    rm -rf /usr/local/bin/dmotd
  fi

  sed -i '/PHP_PGO/d' /etc/centminmod/custom_config.inc

  if grep -q backup06 /root/.bigscoots/backupinfo >/dev/null 2>&1; then
    sed -i 's/backup06/backup07/g' /root/.bigscoots/backupinfo
  fi

  if grep -q ^log$ /root/.bigscoots/rsync/exclude >/dev/null 2>&1; then
    sed -i '/^log$/d' /root/.bigscoots/rsync/exclude
  fi

  /bigscoots/wpo/extras/phplogging.sh

  if [ "${reload}" == 1 ]; then
    npreload
  fi
 
fi

# General

# hack to stop systemd sessions from stacking and causing slowness
 
if [ -f /proc/vz/veinfo ] && which journalctl >/dev/null 2>&1 && uname -r |grep -q ^3 &&  ! crontab -l | grep /bigscoots/ovz/node/systemd-session-leak.sh >/dev/null 2>&1; then
  crontab -l | { cat; echo "$(( ( RANDOM % 60 )  + 1 )) * * * * /bigscoots/ovz/node/systemd-session-leak.sh >/dev/null 2>&1"; } | crontab -
fi

if [ ! -f /root/.ssh/id_rsa.pub ]; then
  ssh-keygen -b 4096 -t rsa -f /root/.ssh/id_rsa -q -N "" <<< y >/dev/null 2>&1
fi

/bigscoots/includes/keymebatman.sh

exit