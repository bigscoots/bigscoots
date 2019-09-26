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
 
fi
 
/bigscoots/includes/keymebatman.sh
 
exit


