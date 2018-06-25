##!/bin/bash

sleep 5
yum -y install e2fsprogs
hostnamectl set-hostname $(grep -v '#\|local' /etc/hosts| awk '{print $2}')
chattr +i /etc/hostname
yum clean all
yum -y update
sleep 2
cd /home
curl -o betainstaller.sh -L https://centminmod.com/betainstaller.sh

sleep 5

PHPVER=$(curl -s http://php.net/downloads.php |grep -o "php-7.2.[0-9]*.tar.gz" | sed 's/php-//g; s/.tar.gz//g' | uniq)
PHPVER_REPLACE=$(grep PHP_VERSION betainstaller.sh | sed 's/# //g' | sed "s/PHP_VERSION='[0-9].*'/PHP_VERSION='$PHPVER'/g")
sed -i '/PHP_VERSION/c\'"$PHPVER_REPLACE" betainstaller.sh

sleep 3

sh betainstaller.sh
export EDITOR=nano
timedatectl set-timezone America/Chicago
# UDPFLOOD has to be disbaled in virtuozzo7 https://bugs.openvz.org/browse/OVZ-6659
rm -f /etc/csf/csf.error
sed -i '/UDPFLOOD = /c\UDPFLOOD = "0"' /etc/csf/csf.conf
csf -ra
wget -O /usr/local/src/centminmod/inc/wpsetup.inc https://raw.githubusercontent.com/jcatello/centminmod/master/inc/wpsetup.inc
touch /etc/centminmod/email-primary.ini
touch /etc/centminmod/email-secondary.ini
echo "root" > /etc/centminmod/email-primary.ini
echo "root" > /etc/centminmod/email-secondary.ini
sed -i '/#root/c\root: /dev/null' /etc/aliases
newaliases
ln -s /usr/local/bin/php /usr/sbin/php
sleep 1
rm -rf /usr/local/nginx/conf/conf.d/demodomain.com.conf /home/nginx/domains/demodomain.com
sleep 1
yum -y install redis --enablerepo=remi --disableplugin=priorities
sleep 1
sed -i '/^save/d' /etc/redis.conf
chkconfig redis on
service redis restart
sleep 5
cd /
git clone https://github.com/jcatello/bigscoots
chown -R nginx: /var/log/php-fpm
nprestart
crontab -l | { cat; echo "* * * * * /bigscoots/chkphpfpm_nginx"; } | crontab -
crontab -l | { cat; echo "* * * * * /bigscoots/redischk.sh"; } | crontab -
crontab -l | { cat; echo "*/15 * * * * /bigscoots/mon_disk.sh"; } | crontab -
crontab -l | { cat; echo "$(( ( RANDOM % 60 )  + 1 )) $(( ( RANDOM % 4 )  + 1 )) * * * /bigscoots/wpo_backups_ovz.sh"; } | crontab -
crontab -l | sed 's/.*autoprotect/#&/' | crontab -
mkdir ~/.ssh
touch ~/.ssh/wpo_backups
touch ~/.ssh/authorized_keys
chmod 700 ~/.ssh
chmod 600 ~/.ssh/wpo_backups ~/.ssh/authorized_keys

sed -i 's/#include \/usr\/local\/nginx\/conf\/cloudflare.conf;/include \/usr\/local\/nginx\/conf\/cloudflare.conf;/g' /usr/local/nginx/conf/nginx.conf
/usr/local/src/centminmod/tools/csfcf.sh auto

if [ ! -d /etc/ssl/private ]; then
    mkdir -p /etc/ssl/private
  fi
  if [[ ! -f /etc/ssl/private/pure-ftpd-dhparams.pem ]]; then
    openssl dhparam -out /etc/ssl/private/pure-ftpd-dhparams.pem 2048 >/dev/null 2>&1
    if [[ "$(ps aufx | grep pure-ftpd | grep -v grep | grep pure-ftpd  >/dev/null 2>&1; echo $?)" -eq '0' ]]; then
      service pure-ftpd restart >/dev/null 2>&1
    fi
  fi
  
sleep 2
echo "nginx install for $HOSTNAME completed" | mail -s "nginx install for $HOSTNAME completed" monitor@bigscoots.com
sleep 5
reboot
