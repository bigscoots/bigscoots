#!/bin/bash

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

PHPVER=$(curl -s http://php.net/downloads.php |grep -o "php-7.1.[0-9][0-9].tar.gz" | sed 's/php-//g; s/.tar.gz//g' | uniq)
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
chkconfig redis on
service redis start
sleep 5
cd /
git clone https://github.com/jcatello/bigscoots
chown -R nginx: /var/log/php-fpm
nprestart
crontab -l | { cat; echo "* * * * * /bigscoots/chkphpfpm_nginx"; } | crontab -
crontab -l | { cat; echo "*/15 * * * * /bigscoots/mon_disk.sh"; } | crontab -
mkdir ~/.ssh
touch ~/.ssh/wpo_backups
chmod 700 ~/.ssh
chmod 600 ~/.ssh/wpo_backups
sleep 2
echo "nginx install for $HOSTNAME completed" | mail -s "nginx install for $HOSTNAME completed" monitor@bigscoots.com
sleep 5
reboot
