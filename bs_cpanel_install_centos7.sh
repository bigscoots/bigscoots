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

DOMAIN=$(echo $(hostname) | awk -F. '{print $2"."$3}')
echo $DOMAIN

EMAIL=$(echo admin@$DOMAIN)
echo $EMAIL

IP=$(ip addr |grep inet |grep -Ev '127.0.0.1|192.168.|::1' | awk '{print $2}' | sed 's/\/.*//g' | head -1)

echo
echo "######################################################"
echo "Disable initial setup screen and configure it."
echo "######################################################"
sleep 1

touch /etc/.whostmgrft
echo > /etc/wwwacct.conf

echo ADDR $IP >> /etc/wwwacct.conf
echo NSTTL 86400 >> /etc/wwwacct.conf
echo TTL 14400 >> /etc/wwwacct.conf
echo SCRIPTALIAS y >> /etc/wwwacct.conf
echo NS2 ns2.$DOMAIN >> /etc/wwwacct.conf
echo ETHDEV venet0:0 >> /etc/wwwacct.conf
echo HOST $HOSTNAME >> /etc/wwwacct.conf
echo MINUID 500 >> /etc/wwwacct.conf
echo CONTACTEMAIL $EMAIL >> /etc/wwwacct.conf
echo HOMEMATCH home >> /etc/wwwacct.conf
echo CONTACTPAGER >> /etc/wwwacct.conf
echo NS ns1.$DOMAIN >> /etc/wwwacct.conf
echo NS4 >> /etc/wwwacct.conf
echo HOMEDIR /home >> /etc/wwwacct.conf
echo NS3 >> /etc/wwwacct.conf
echo LOGSTYLE combined >> /etc/wwwacct.conf
echo DEFMOD paper_lantern >> /etc/wwwacct.conf
echo DEFWEBMAILTHEME paper_lantern >> /etc/wwwacct.conf

echo $EMAIL > /root/.forward

mkdir -p /root/cpanel_profile
cp -rf /bigscoots/cpanel.config /root/cpanel_profile/cpanel.config
cp -rf /bigscoots/bigscoots.json /etc/cpanel_initial_install_ea4_profile.json

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


echo
echo "######################################################"
echo "Install Perl and Screen if its not already, and start cPanel installation."
echo "######################################################"
sleep 3

yum install perl screen -y
cd /home && curl -o latest -L https://securedownloads.cpanel.net/latest && sh latest

echo
echo "#####################################"
echo "#             BigScoots             #"
echo "# Fully Managed cPanel Server Setup #"
echo "#####################################"

sleep 1

echo
echo "######################################################"
echo "Disable cphulk"
echo "######################################################"
sleep 1

rm -f /var/cpanel/hulkd/enabled
/usr/local/cpanel/etc/init/stopcphulkd
/usr/local/cpanel/bin/cphulk_pam_ctl --disable

echo
echo "######################################################"
echo "Install addons"
echo "######################################################"
sleep 1

mkdir /home/installtmp
cd /home/installtmp
wget -N http://www.networkpanda.com/scripts/cel_install
sh cel_install
wget https://download.configserver.com/csf.tgz
wget https://download.configserver.com/cmc.tgz
wget https://download.configserver.com/cse.tgz
wget https://download.configserver.com/cmq.tgz
wget https://download.configserver.com/cmm.tgz
wget http://download.ndchost.com/accountdnscheck/latest-accountdnscheck
wget https://s3.amazonaws.com/uploads.hipchat.com/31137/205915/8wnl7tivlp88pfm/rkhunter-1.4.0.tar.gz
sh latest-accountdnscheck
tar -zxvf csf.tgz
tar -zxvf cmc.tgz
tar -zxvf cse.tgz
tar -zxvf cmq.tgz
tar -zxvf cmm.tgz
tar -zxvf rkhunter-1.4.0.tar.gz
cd cmc ; sh install.sh ; cd ..
cd cse ; sh install.sh ; cd ..
cd cmq ; sh install.sh ; cd ..
cd cmm ; sh install.sh ; cd ..
cd csf ; sh install.cpanel.sh ; cd ..
cd rkhunter-1.4.0 ; ./installer.sh --install

echo
echo "######################################################"
echo "Install and configure CSF + PureFTPD"
echo "######################################################"
sleep 1

sed -i 's/TESTING = "1"/TESTING = "0"/g' /etc/csf/csf.conf
sed -i '/TCP_IN = "/c\TCP_IN = "20,21,22,25,26,53,80,110,143,443,465,587,993,995,111,2049,2077,2078,2082,2083,2086,2087,2095,2096,2222,49152:65534"' /etc/csf/csf.conf
sed -i '/TCP_OUT = "/c\TCP_OUT = "20,21,22,25,26,37,43,53,80,110,113,443,587,873,111,2049,2086,2087,2089,2703"' /etc/csf/csf.conf
sed -i '/UDP_OUT = "/c\UDP_OUT = "20,21,53,111,113,123,873,2049,6277"' /etc/csf/csf.conf
sed -i '/UDP_IN = "/c\UDP_IN = "20,21,53,111,2049"' /etc/csf/csf.conf
sed -i 's/LF_SCRIPT_ALERT = "0"/LF_SCRIPT_ALERT = "1"/g' /etc/csf/csf.conf
sed -i '/PT_USERPROC = /c\PT_USERPROC = "0"' /etc/csf/csf.conf
sed -i '/PT_USERTIME = /c\PT_USERTIME = "0"' /etc/csf/csf.conf
sed -i '/LF_INTEGRITY = /c\LF_INTEGRITY = "0"' /etc/csf/csf.conf
sed -i '/PT_USERMEM = /c\PT_USERMEM = "0"' /etc/csf/csf.conf

# UDPFLOOD has to be disbaled in virtuozzo7 https://bugs.openvz.org/browse/OVZ-6659
sed -i '/UDPFLOOD = /c\UDPFLOOD = "0"' /etc/csf/csf.conf
sed -i '/LF_DIRWATCH = /c\LF_DIRWATCH = "0"' /etc/csf/csf.conf
sed -i 's/LF_EMAIL_ALERT = "1"/LF_EMAIL_ALERT = "0"/g' /etc/csf/csf.conf
sed -i 's/LF_TRIGGER = "0"/LF_TRIGGER = "20"/g' /etc/csf/csf.conf
sed -i 's/LF_TRIGGER_PERM = "1"/LF_TRIGGER_PERM = "900"/g' /etc/csf/csf.conf
sed -i 's/CT_EMAIL_ALERT = "1"/CT_EMAIL_ALERT = "0"/g' /etc/csf/csf.conf
sed -i 's/PT_USERKILL_ALERT = "1"/PT_USERKILL_ALERT = "0"/g' /etc/csf/csf.conf
sed -i 's/PS_EMAIL_ALERT = "1"/PS_EMAIL_ALERT = "0"/g' /etc/csf/csf.conf
sed -i 's/PORTKNOCKING_ALERT = "1"/PORTKNOCKING_ALERT = "0"/g' /etc/csf/csf.conf
sed -i 's/LT_EMAIL_ALERT = "1"/LT_EMAIL_ALERT = "0"/g' /etc/csf/csf.conf
sed -i 's/RESTRICT_SYSLOG = "0"/RESTRICT_SYSLOG = "2"/g' /etc/csf/csf.conf
sed -i 's/LF_PERMBLOCK_ALERT = "1"/LF_PERMBLOCK_ALERT = "0"/g' /etc/csf/csf.conf
sed -i 's/LF_NETBLOCK_ALERT = "1"/LF_NETBLOCK_ALERT = "0"/g' /etc/csf/csf.conf
sed -i 's/RT_RELAY_ALERT = "1"/RT_RELAY_ALERT = "0"/g' /etc/csf/csf.conf
sed -i 's/LF_ALERT_TO = ""/LF_ALERT_TO = "manage@bigscoots.com"/g' /etc/csf/csf.conf
sed -i 's/X_ARF_TO = ""/X_ARF_TO = "manage@bigscoots.com"/g' /etc/csf/csf.conf

sed -i '/PassivePortRange/c\PassivePortRange          49152 65534' /etc/pure-ftpd.conf


echo
echo "######################################################"
echo "Disable IPv6"
echo "######################################################"
sleep 1

/sbin/sysctl -w net.ipv6.conf.default.disable_ipv6=1
/sbin/sysctl -w net.ipv6.conf.all.disable_ipv6=1

echo
echo "######################################################"
echo "mysqltuner easy access"
echo "######################################################"
sleep 1

cd / ; wget https://raw.github.com/major/MySQLTuner-perl/master/mysqltuner.pl --no-check-certificate; chmod +x mysqltuner.pl ; mv mysqltuner.pl /usr/sbin

echo
echo "######################################################"
echo "PHP config + harden functions + Passive FTP ports for pureftpd"
echo "######################################################"
sleep 1

sed -i '/allow_url_fopen = /c\allow_url_fopen = On' /opt/cpanel/ea-php*/root/etc/php.ini /opt/cpanel/ea-php*/root/etc/php.d/local.ini 
sed -i '/max_execution_time = /c\max_execution_time = 120' /opt/cpanel/ea-php*/root/etc/php.ini /opt/cpanel/ea-php*/root/etc/php.d/local.ini
sed -i '/max_input_time = /c\max_input_time = -1' /opt/cpanel/ea-php*/root/etc/php.ini /opt/cpanel/ea-php*/root/etc/php.d/local.ini
sed -i '/memory_limit = /c\memory_limit = 256M' /opt/cpanel/ea-php*/root/etc/php.ini /opt/cpanel/ea-php*/root/etc/php.d/local.ini
sed -i '/upload_max_filesize = /c\upload_max_filesize = 128M' /opt/cpanel/ea-php*/root/etc/php.ini /opt/cpanel/ea-php*/root/etc/php.d/local.ini
sed -ie 's/#Port.*[0-9]$/Port 2222/gI' /etc/ssh/sshd_config
sed -i 's/#UseDNS yes/UseDNS no/g' /etc/ssh/sshd_config
sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config
sed -i 's/ChallengeResponseAuthentication yes/ChallengeResponseAuthentication no/g' /etc/ssh/sshd_config
sed -i 's/#PermitRootLogin yes/PermitRootLogin without-password/g' /etc/ssh/sshd_config

echo
echo "######################################################"
echo "Restart some services that need changes to take effect."
echo "######################################################"
sleep 1

service httpd restart
csf -r
service pure-ftpd restart
service mysql restart
service sshd restart

echo
echo "######################################################"
echo "Stop uneceesary services"
echo "######################################################"
sleep 1

service xinetd stop
chkconfig xinetd off
service portreserve stop
chkconfig portreserve off
service rpcbind stop
chkconfig rpcbind off
service saslauthd stop
chkconfig saslauthd off

yum remove iputils -y
rpm -ivh https://buildlogs.centos.org/c7.1511.00/iputils/20151120190818/20121221-7.el7.x86_64/iputils-20121221-7.el7.x86_64.rpm
yum -y install initscripts

echo
echo "######################################################"
echo "Install maldet and clamav"
echo "######################################################"
sleep 1

/scripts/update_local_rpm_versions --edit target_settings.clamav installed
/scripts/check_cpanel_rpms --fix --targets=clamav
cd /usr/local/src/
wget http://www.rfxn.com/downloads/maldetect-current.tar.gz
tar -xzf maldetect-current.tar.gz
cd maldetect-*
sh ./install.sh
ln -s /usr/local/cpanel/3rdparty/bin/clamscan /usr/local/sbin/clamscan
ln -s /usr/local/cpanel/3rdparty/bin/freshclam /usr/local/sbin/freshclam
maldet -d
maldet -u
freshclam

echo
echo "######################################################"
echo "Setting minimum password strength to 50"
echo "######################################################"
sleep 1

whmapi1 setminimumpasswordstrengths default=50

echo
echo "######################################################"
echo "Completed - Server will reboot now."
echo "######################################################"

sleep 3

echo "cPanel install for $HOSTNAME completed!" | mail -s "cPanel install for $HOSTNAME completed!" monitor@bigscoots.com

sleep 1

/usr/sbin/reboot



