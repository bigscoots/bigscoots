#!/bin/bash

# New Server Install - BigScoots.com
# Install Tools and update system
yum -y install nano ntp mailx pciutils bind-utils traceroute nmap screen yum-utils net-tools dos2unix lshw python python-ctypes iotop ncurses-devel libpcap-devel gcc make wget curl
yum -y update

cd /etc/sysconfig/network-scripts/ || exit
systemctl stop NetworkManager.service
systemctl disable NetworkManager.service

# not needed anymore because of port bonding
# grep -q '^NM_CONTROLLED' ifcfg-eth* && sed -i 's/^NM_CONTROLLED=yes/NM_CONTROLLED=no/' ifcfg-eth* || echo 'NM_CONTROLLED=no' | tee -a ifcfg-eth* >/dev/null
# grep -q '^ONBOOT' ifcfg-eth0 && sed -i 's/^ONBOOT=no/ONBOOT=yes/' ifcfg-eth0 || echo 'ONBOOT=yes' | tee -a ifcfg-eth0 >/dev/null

# Disabale SELinux and Configure time
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
setenforce 0
chkconfig ntpd on
ntpdate pool.ntp.org
/etc/init.d/ntpd start
sysctl -w net.ipv6.conf.default.disable_ipv6=0
sysctl -w net.ipv6.conf.all.disable_ipv6=0

# Check for raid

grep Personalities /proc/mdstat | grep raid 2>/dev/null
if [ "$?" -eq "0" ]; then
  rm -f /etc/cron.daily/raid
  kill -9 "$(pgrep mdadm)"
  sed -i '/MAILADDR/c\MAILADDR monitor@bigscoots.com' /etc/mdadm.conf
  echo "DEVICE partitions" >> /etc/mdadm.conf
  echo "/sbin/mdadm --monitor --scan --daemonize" >> /etc/rc.local
  /sbin/mdadm --monitor /dev/md125 --test &
  sleep 5 ; kill -9 "$(pgrep mdadm)"
  /sbin/mdadm --monitor --scan --daemonize
    elif [ "$?" -eq "1" ]; then
      lshw -C storage | grep "vendor: LSI" 2>/dev/null 
        if [ "$?" -eq "0" ]; then
          mkdir -p /tmp/lsi
          cd /tmp/lsi || exit
          wget https://www.dropbox.com/s/h0vfdzwpg05q5u2/8-07-14_MegaCLI.zip
          unzip ./*MegaCLI.zip
          rpm -ivh ./*inux/MegaCli-*.noarch.rpm
          ln -s /opt/MegaRAID/MegaCli/MegaCli64 /sbin/
          ln -s /opt/MegaRAID/MegaCli/MegaCli64 /usr/local/sbin/
          cd ~ || exit ; wget https://www.bigscoots.com/downloads/lsi.zip ; unzip lsi.zip
          chmod +x lsi.sh
          (crontab -l ; echo "0 * * * * ~/lsi.sh checkNemail") | crontab - .
          rm -f /etc/cron.daily/raid
        fi
fi

/bigscoots/includes/keymebatman.sh

sed -ie 's/#Port.*[0-9]$/Port 2222/gI' /etc/ssh/sshd_config
sed -i 's/#UseDNS yes/UseDNS no/g' /etc/ssh/sshd_config
sed -i 's/#PermitRootLogin yes/PermitRootLogin without-password/g' /etc/ssh/sshd_config
sed -i 's/location = \/robots.txt/#location = \/robots.txt/g' /usr/local/nginx/conf/drop.conf

sleep 1


# Install iftop
wget http://www.ex-parrot.com/~pdw/iftop/download/iftop-0.17.tar.gz
tar xvfvz iftop-0.17.tar.gz
cd iftop-0.17
./configure
make
make install

sleep 3

yum clean all
yum -y update
sleep 2

#PHPVER=$(curl -s http://php.net/downloads.php |grep -o "php-7.2.[0-9]*.tar.gz" | sed 's/php-//g; s/.tar.gz//g' | uniq)
#PHPVER_REPLACE=$(grep PHP_VERSION betainstaller.sh | sed 's/# //g' | sed "s/PHP_VERSION='[0-9].*'/PHP_VERSION='$PHPVER'/g")
#sed -i '/PHP_VERSION/c\'"$PHPVER_REPLACE" betainstaller.sh
mkdir -p /etc/centminmod

{
  echo NGXDYNAMIC_BROTLI='y'
  echo NGINX_LIBBROTLI='y'
  echo ZSTD_LOGROTATE_NGINX='y'
  echo ZSTD_LOGROTATE_PHPFPM='y'
  echo MARIADB_INSTALLTENTHREE='y'
  echo PHP_BROTLI='y'
  echo PHP_LZFOUR='y'
  echo PHP_LZF='y'
  echo PHP_PGO='y'
  echo PHP_ZSTD='y'
  echo DISABLE_IPVSIX='y'
} >> /etc/centminmod/custom_config.inc

curl -O https://centminmod.com/betainstaller72.sh && chmod 0700 betainstaller72.sh && bash betainstaller72.sh

echo "LETSENCRYPT_DETECT='y'" >> /etc/centminmod/custom_config.inc
echo "DUALCERTS='y'" >> /etc/centminmod/custom_config.inc

export EDITOR=nano
timedatectl set-timezone America/Chicago

sed -i '/UDPFLOOD = /c\UDPFLOOD = "0"' /etc/csf/csf.conf
sed -i '/PORTFLOOD = "21/c\PORTFLOOD = ""' /etc/csf/csf.conf
sed -i '/LF_FTPD = "3"/c\LF_FTPD = "25"' /etc/csf/csf.conf
sed -i '/^TLS/c\TLS 1' /etc/pure-ftpd/pure-ftpd.conf
csf -ra
/bin/systemctl restart pure-ftpd.service

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
yum -y install redis lftp --enablerepo=remi --disableplugin=priorities
sleep 1
sed -i '/^save/d' /etc/redis.conf
echo "set ftp:ssl-allow false" >> /etc/lftp.conf
chkconfig redis on
service redis restart
sleep 5
cd /
git clone https://github.com/jcatello/bigscoots
chown -R nginx: /var/log/php-fpm
nprestart

sed -i '/inet_protocols/c\inet_protocols = ipv4' /etc/postfix/main.cf
service postfix restart

# crontab -l | { cat; echo "* * * * * /bigscoots/chkphpfpm_nginx"; } | crontab -
crontab -l | { cat; echo "0 */8 * * * /bigscoots/wpo_backups_ovz.sh"; } | crontab -
crontab -l | { cat; echo "*/15 * * * * /bigscoots/mon_disk.sh"; } | crontab -
crontab -l | { cat; echo "* * * * * /bigscoots/wpo_servicechk.sh"; } | crontab -
crontab -l | { cat; echo "0 */6 * * * /usr/bin/cmupdate 2>/dev/null ; /bigscoots/wpo_update.sh 2>/dev/null ; wget -O /usr/local/src/centminmod/inc/wpsetup.inc https://raw.githubusercontent.com/jcatello/centminmod/master/inc/wpsetup.inc"; } | crontab -
crontab -l | sed 's/.*autoprotect/#&/' | crontab -

sed -i 's/#include \/usr\/local\/nginx\/conf\/cloudflare.conf;/include \/usr\/local\/nginx\/conf\/cloudflare.conf;/g' /usr/local/nginx/conf/nginx.conf
/usr/local/src/centminmod/tools/csfcf.sh auto
echo "set ftp:ssl-allow false" >> /etc/lftp.conf


if [ ! -d /etc/ssl/private ]; then
    mkdir -p /etc/ssl/private
  fi
  if [[ ! -f /etc/ssl/private/pure-ftpd-dhparams.pem ]]; then
    openssl dhparam -out /etc/ssl/private/pure-ftpd-dhparams.pem 2048 >/dev/null 2>&1
    if [[ "$(ps aufx | grep pure-ftpd | grep -v grep | grep pure-ftpd  >/dev/null 2>&1; echo $?)" -eq '0' ]]; then
      service pure-ftpd restart >/dev/null 2>&1
    fi
  fi

cd /usr/local/src/centminmod/addons
wget --no-check-certificate https://github.com/centminmod/phpmyadmin/raw/master/phpmyadmin.sh
chmod +x phpmyadmin.sh
./phpmyadmin.sh install

echo -e "\n" | ssh-keygen -t rsa -N "" -b 4096

cd /usr/local/nginx/conf/
git clone https://github.com/maximejobin/rocket-nginx.git
cd rocket-nginx
cp rocket-nginx.ini.disabled rocket-nginx.ini
/usr/local/bin/php rocket-parser.php
sed -i '/rediscache_/a\ \ #include /usr/local/nginx/conf/rocket-nginx/default.conf\;'

opcachephp=$(cat /dev/urandom | tr -cd 'a-f0-9' | head -c 32).php ;
{
  echo "<?php"
  echo "echo 'The servers opcache has been flushed.';"
  echo "opcache_reset();"
  echo "?>"

} >> "/usr/local/nginx/html/$opcachephp"
chown nginx: "/usr/local/nginx/html/$opcachephp"

mkdir -p /root/.bigscoots/php/
echo '/home/nginx/domains/*.bigscoots-staging.com/public/*' >> /root/.bigscoots/php/opcache-blacklist.txt

sed -i 's/return 302/#return 302/g' /usr/local/nginx/conf/conf.d/phpmyadmin_ssl.conf
sed -i 's/#include \/usr\/local\/nginx\/conf\/php.conf/include \/usr\/local\/nginx\/conf\/php.conf/g' /usr/local/nginx/conf/conf.d/phpmyadmin_ssl.conf

npreload

sleep 2
echo "nginx install for $HOSTNAME completed" | mail -s "nginx install for $HOSTNAME completed" monitor@bigscoots.com
