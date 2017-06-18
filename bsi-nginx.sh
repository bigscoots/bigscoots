#!/bin/bash

sleep 30
yum clean all
yum -y update
sleep 2
cd /home
curl -o betainstaller.sh -L https://centminmod.com/betainstaller.sh
sleep 5
sh betainstaller.sh
export EDITOR=nano
timedatectl set-timezone America/Chicago
# UDPFLOOD has to be disbaled in virtuozzo7 https://bugs.openvz.org/browse/OVZ-6659
sed -i '/UDPFLOOD = /c\UDPFLOOD = "0"' /etc/csf/csf.conf
csf -ra
wget -O /usr/local/src/centminmod/inc/wpsetup.inc https://raw.githubusercontent.com/jcatello/centminmod/master/inc/wpsetup.inc
touch /etc/centminmod/email-primary.ini
touch /etc/centminmod/email-secondary.ini
echo "root" > /etc/centminmod/email-primary.ini
echo "root" > /etc/centminmod/email-secondary.ini
sed -i '/#root/c\root: /dev/null' /etc/aliases
/bin/newaliases
sleep 1
rm -rf /usr/local/nginx/conf/conf.d/demodomain.com.conf /home/nginx/domains/demodomain.com
sleep 1
yum -y install redis --enablerepo=remi --disableplugin=priorities
chkconfig redis on
service redis start
