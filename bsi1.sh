#!/bin/bash

clear

echo
echo "#####################################"
echo "#             BigScoots             #"
echo "# Fully Managed cPanel Server Setup #"
echo "#####################################"

sleep 2

echo
echo "######################################################"
echo "Make sure to set a valid hostname.(ex. server.domain.com)"
echo "Make sure to set the rDNS for the hostname"
echo "######################################################"
sleep 3

echo
echo "######################################################"
echo "Remove YUM groups"
echo "######################################################"
sleep 3

yum groupremove -y "Mono" "Mail Server"

echo
echo "######################################################"
echo "Disable iptables, update the server and set the timezone(Chicago)"
echo "######################################################"
sleep 3

chkconfig iptables off
service iptables stop
yum -y update
rm -f /etc/localtime
ln -s /usr/share/zoneinfo/America/Chicago /etc/localtime

mkdir -p /var/cpanel/easy/apache/
wget -O /var/cpanel/easy/apache/prefs.yaml dev.bigscoots.com/d/prefs.yaml
wget -O /etc/cp_easyapache_profile.yaml dev.bigscoots.com/d/cp_easyapache_profile.yaml


echo
echo "######################################################"
echo "Install Perl and Screen if its not already, and start cPanel installation."
echo "######################################################"
sleep 3

yum install perl screen -y
cd /home ; wget -N http://httpupdate.cpanel.net/latest ; sh latest