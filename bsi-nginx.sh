##!/bin/bash

sleep 5
yum -y install e2fsprogs
# chattr -i /etc/hostname
# hostnamectl set-hostname "wpo.$(echo $HOSTNAME | sed 's/www.//g')"
chattr +i /etc/hostname
yum clean all
yum -y update
sleep 2
cd /home

sleep 5

#PHPVER=$(curl -s http://php.net/downloads.php |grep -o "php-7.2.[0-9]*.tar.gz" | sed 's/php-//g; s/.tar.gz//g' | uniq)
#PHPVER_REPLACE=$(grep PHP_VERSION betainstaller.sh | sed 's/# //g' | sed "s/PHP_VERSION='[0-9].*'/PHP_VERSION='$PHPVER'/g")
#sed -i '/PHP_VERSION/c\'"$PHPVER_REPLACE" betainstaller.sh

sleep 3

sed -ie 's/#Port.*[0-9]$/Port 2222/gI' /etc/ssh/sshd_config
sed -i 's/#UseDNS yes/UseDNS no/g' /etc/ssh/sshd_config
# sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config
# sed -i 's/ChallengeResponseAuthentication yes/ChallengeResponseAuthentication no/g' /etc/ssh/sshd_config
sed -i 's/#PermitRootLogin yes/PermitRootLogin without-password/g' /etc/ssh/sshd_config

mkdir -p /etc/centminmod

sleep 1

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
  echo PHPFINFO='y'
  echo DISABLE_IPVSIX='y'
  } >> /etc/centminmod/custom_config.inc

curl -O https://centminmod.com/betainstaller73.sh && chmod 0700 betainstaller73.sh && bash betainstaller73.sh

echo "LETSENCRYPT_DETECT='y'" >> /etc/centminmod/custom_config.inc
echo "DUALCERTS='y'" >> /etc/centminmod/custom_config.inc


export EDITOR=nano
timedatectl set-timezone America/Chicago
# UDPFLOOD has to be disbaled in virtuozzo7 https://bugs.openvz.org/browse/OVZ-6659
rm -f /etc/csf/csf.error
sed -i '/UDPFLOOD = /c\UDPFLOOD = "0"' /etc/csf/csf.conf
sed -i '/PORTFLOOD = "21/c\PORTFLOOD = ""' /etc/csf/csf.conf
sed -i '/LF_FTPD = "3"/c\LF_FTPD = "25"' /etc/csf/csf.conf
sed -i '/^TLS/c\TLS 1' /etc/pure-ftpd/pure-ftpd.conf
echo "67.202.70.147 # WPO NEXUS" >> /etc/csf/csf.allow
csf -ra
/bin/systemctl restart pure-ftpd.service
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
chkconfig redis on
service redis restart
sleep 5
cd /
git clone https://github.com/jcatello/bigscoots
chown -R nginx: /var/log/php-fpm
nprestart

postconf -e inet_protocols=ipv4
/bin/systemctl restart postfix.service
postfix reload

sed -i '/SystemMaxUse/c\SystemMaxUse=500M'  /etc/systemd/journald.conf 
systemctl restart systemd-journald

# crontab -l | { cat; echo "* * * * * /bigscoots/chkphpfpm_nginx"; } | crontab -
crontab -l | { cat; echo "* * * * * /bigscoots/wpo_servicechk.sh"; } | crontab -
# crontab -l | { cat; echo "0 */8 * * * /bigscoots/mon_disk.sh"; } | crontab -
crontab -l | { cat; echo "0 */6 * * * /usr/bin/cmupdate 2>/dev/null ; /bigscoots/wpo_update.sh 2>/dev/null ; wget -O /usr/local/src/centminmod/inc/wpsetup.inc https://raw.githubusercontent.com/jcatello/centminmod/master/inc/wpsetup.inc"; } | crontab -
crontab -l | { cat; echo "$(( ( RANDOM % 60 )  + 1 )) $(( ( RANDOM % 4 )  + 1 )) * * * /bigscoots/wpo_backups_ovz.sh"; } | crontab -
crontab -l | sed 's/.*autoprotect/#&/' | crontab -
mkdir ~/.ssh
touch ~/.ssh/wpo_backups
touch ~/.ssh/authorized_keys
chmod 700 ~/.ssh
chmod 600 ~/.ssh/wpo_backups ~/.ssh/authorized_keys

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
  
/bigscoots/includes/keymebatman.sh

cd /usr/local/src/centminmod/addons
wget --no-check-certificate https://github.com/centminmod/phpmyadmin/raw/master/phpmyadmin.sh
chmod +x phpmyadmin.sh
./phpmyadmin.sh install

sed -i 's/listen 443 ssl spdy/listen 443 ssl http2/g' /usr/local/nginx/conf/conf.d/phpmyadmin_ssl.conf
sed -i 's/spdy_headers_comp/#spdy_headers_comp/g' /usr/local/nginx/conf/conf.d/phpmyadmin_ssl.conf

echo -e "\n" | ssh-keygen -t rsa -N "" -b 4096

wget -O /usr/local/src/centminmod/inc/wpsetup.inc https://raw.githubusercontent.com/jcatello/centminmod/master/inc/wpsetup.inc

cd /usr/local/nginx/conf/
git clone https://github.com/maximejobin/rocket-nginx.git
cd rocket-nginx
cp rocket-nginx.ini.disabled rocket-nginx.ini
/usr/local/bin/php rocket-parser.php
sed -i '/rediscache_/a\ \ #include /usr/local/nginx/conf/rocket-nginx/default.conf\;'

/root/tools/phpmyadmin_update.sh

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
sed -i 's/location = \/robots.txt/#location = \/robots.txt/g' /usr/local/nginx/conf/drop.conf
sed -i 's/default-character-set/#default-character-set/g' /etc/my.cnf
sed -i 's/character-set-server/#character-set-server/g' /etc/my.cnf
sed -i 's/;request_slowlog_timeout = 0/request_slowlog_timeout = 20/g' /usr/local/etc/php-fpm.conf

npreload
systemctl daemon-reload
/etc/init.d/mysql restart

BSPATH=/root/.bigscoots

mkdir -p "$BSPATH"
touch "$BSPATH"/backupinfo

wget -O /usr/local/src/centminmod/inc/wpsetup.inc https://raw.githubusercontent.com/jcatello/centminmod/master/inc/wpsetup.inc

yum -y remove mlocate

touch /root/.bigscoots/wpo.installed

sleep 2
echo "nginx install for $HOSTNAME completed" | mail -s "nginx install for $HOSTNAME completed" monitor@bigscoots.com
sleep 5
# reboot
