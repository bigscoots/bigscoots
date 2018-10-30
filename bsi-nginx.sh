##!/bin/bash

sleep 5
yum -y install e2fsprogs
chattr -i /etc/hostname
hostnamectl set-hostname "wpo.$(echo $HOSTNAME | sed 's/www.//g')"
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

sed -ie 's/#Port.*[0-9]$/Port 2222/gI' /etc/ssh/sshd_config
sed -i 's/#UseDNS yes/UseDNS no/g' /etc/ssh/sshd_config
# sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config
# sed -i 's/ChallengeResponseAuthentication yes/ChallengeResponseAuthentication no/g' /etc/ssh/sshd_config
sed -i 's/#PermitRootLogin yes/PermitRootLogin without-password/g' /etc/ssh/sshd_config

sleep 1

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
crontab -l | { cat; echo "* * * * * /bigscoots/chkphpfpm_nginx"; } | crontab -
crontab -l | { cat; echo "* * * * * /bigscoots/redischk.sh"; } | crontab -
crontab -l | { cat; echo "0 */8 * * * /bigscoots/mon_disk.sh"; } | crontab -
crontab -l | { cat; echo "0 */6 * * * /usr/bin/cmupdate 2>/dev/null"; } | crontab -
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
  
  mkdir ~/.ssh
touch ~/.ssh/authorized_keys
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys

echo "# Justin - BigScoots.com" >> ~/.ssh/authorized_keys

echo ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAgEAn+cOO+QgKiuntfsPmJ8NtUsGNmOlT3LKjRhR3Yk9paGYul/f+A0wP0YBp/ANpNPUeKO7TqTnyzL8PIpCUXOyJ5Nsoo2X3Bv2jERXj54qzX5BD8cDwLJ8ACIIy9O0tmG9vycAqE0JApEsgfeUN8NVe3uaVhdjfPZMgGhBZZvZavFFqdRkeDcLXhw+fuBQpN3inELYU2YVeR6XOYcavU0zFAC7zbhaS3x71xmXHfyVueJRsBUzrFu56Yag4XrcIopvoGy2SHX929SG34wa5tCtfpdkinxJpru/9fmKKJKMMEW49VS0cOC2dFjm67zR+RoTsyhG6QCLPIPwjDJry9JZ3bZ4YI74J+TXsjB7b1k33Vqcd2hIVJ3phhcWQiQ8sfoUMZQfWr6F1s1+Q2N+8G7l6rdMheLemzqH+ZKFC0QxhNei4qLFVDfVds7HnODn7V7kaG07ge0usN9P604vgVp33mtD0dsOzNAW21EBTjurDIu/akbYqUBBPPhDvlWotYylY9+o6rQyyVtrcBARr3mbAkZdrIpjLyOlXb/ZoLzl3b1ciBV+WmwaJwdYzQqiXDCz4W8zH4RwJFaBa6StPlF7Xau6g1Dnzd2UjtUmft+ciQNHzPqUnwG4V41kvqu3hhM8usGlSMGUa8wX1RWj/ZkpuMOeaamBzVbaIbn9UsKuBhk= rsa-key-20161116 >> ~/.ssh/authorized_keys
chmod 700 ~/.ssh ; chmod 600 ~/.ssh/authorized_keys

echo "# Xavier - BigScoots.com" >> ~/.ssh/authorized_keys

echo ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAgEAx/wguQjxQ/h3JD6Tit6hHvXZFszRnQQMMVOEIvn0WUxk1+O6VSKu1soc9E+gLg1PK8tUesgFyluRAjewyR8JTbBiP5ZCDddt2wyuBV8qEtJV7og96gzqABp28CY54f0ER8JBF7dtB1cjawliL0CquiJnBhWO4Q4VbBTr/EXZghPtWJKHGBwX7ziZKxcsSpJfrCbYbU1caUkOjkHSNdnKX6KhHK6pCaL8b27sDBwqZrv+YGfheQXnXjiEGW8/oJ8mSP6mawVlxFocGCZtfrjKsr5zDREalLmOAdXsFw/evID95tqyRZt4V5eirvtCA5P1N7+6oTDJ2XvCkjUtHSrzHXXZ5z6UkTJqCaqC3bRVbxVRkFWjxYqLBZe8YTBzwOoUXVhP2kYPxz97hKhblhHWpO5R1GtT0ragVdjeXxtLWgs2eTqmGQat4x4PxeEAUOjxeY48UBMRG50XCHkdVylZrgwaDBr1IV3lCZc8BtDJKT1QKygIZkHVQfaqfvtQ1oFB6Nx5SNzJ7mHvmIQvaj+tWSOTBdIny6DO2RhPCJBz3UNUDUuul9mw1j5Gsv0VvudFDz4DxOjGUlk519KoeNyRvBuDRwVb51HUGX/4lykHfaG7KMmy6V35JGEzna4Voy6VVQr2xp2eNYlbw15UcFfA1BXRWaPmYiNGeDXvWn8QZ/k= rsa-key-20170802 >> ~/.ssh/authorized_keys

echo "# Jay - BigScoots.com" >> ~/.ssh/authorized_keys

echo ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAgEAjOtX/QuK+gv+yxQRvCRe3gFDvCR3qmjByRAbDq8I3FKBNLMUpDARMea8ISR/D/xgD1s30WWCXTtUQK9Qem0XSYSn9qdaKp30f7j5APfoL8bAect0i4XR/RpJBTbuH1Mt1WMaqKB5w8cuo7Rwo3dRE7iUZKlSjJFpofQ+hKAWFdnu82MgmetzbQtvR2Ta1ymLul2LK3bluy0tovyB4cWEFGFUwayK999tEvXJ3+T3PxEonVSUS2Ay3xfXJwK+yIigU/MQqf72bKlMRhGEuLnozlYwm5y97qJFKPIDSp4YN8ztmBeKLTBvQkSD32HctxKY4z2BzTev7Ip1Xhil6DDPY7Y/PoQwQ+xBP6jk6OpJud5P49lHIT16obkSW9L8fD5SHT+Ov7AJv0/cclY2VBbJBPKjCy5q+qeiVMSbGkAcRLp40UTTtWkFP6nmWjfPK1sytco5dy1GhoC6mwPrwLmq+mvMpa721NVpcw25/G7o7zXBXZ56i/7ImqlqwCa4/VNEioabhvM3zODLOfbqDXMeZVwIOAoshmAhGYLCm/+OdTi+J+D0+ub6k7EVze3h5/0c4rDYOib62Urp/G3ZUDSakLUj8KhyNLc5UaFbfQPD5ePiw2KQ9qO83Ikkt90oHjFQwW+vu8ribYgEsR/0qk8qTjFL8GYXRsRmqJaMyRFz18U= rsa-key-20170802 >> ~/.ssh/authorized_keys

cd /usr/local/src/centminmod/addons
wget --no-check-certificate https://github.com/centminmod/phpmyadmin/raw/master/phpmyadmin.sh
chmod +x phpmyadmin.sh
./phpmyadmin.sh install

  
sleep 2
echo "nginx install for $HOSTNAME completed" | mail -s "nginx install for $HOSTNAME completed" monitor@bigscoots.com
sleep 5
# reboot
