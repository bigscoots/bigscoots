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


mkdir ~/.ssh
touch ~/.ssh/authorized_keys

echo "# WPO NEXUS - BigScoots.com" >> ~/.ssh/authorized_keys
echo from=\"67.202.70.147\" ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCrhMe1Ld+wFXEhpXzjspZOHywCpp0DLw1Qx89oOofp1XGPoDf3G/1iT/OnrC+51hrNwope715EOab7Jd5fYTOSg08G0Tzxd44SSDpkC9OTdsQc0D2sFzWfM5LFdIFomwmT0hCzwhZkZqVNDWYPwOrtjpL+x1YGOs5+JE1WjE9cHSPvowL62P5T6Y56VQUIxtdy08SJX/IXazSzd8VWfbwCBsSPLccwk5+JbCmJXtvRTW37Nxao+oDuaT+vsbso6VnOB0PJusx0CgdyPH1+b4XfNOuaO/wAPvD6akGhkGbmjBxLxBrf1kpx7MEpaLmjPHiD0mKJgTf05weVAKygppTKhT4DE37349jbBFLLVDWrTOMeRLDQr3jYIGhwUSTA4z8+a1QM9pxb7UTN9afZ4Gn/mfqSSdw8meEYTnBSeyqF4XzeC0rN+n06uYiobdzXMB6CQ9+SbPwTovpvU/2oyz9/R1jk3oR+FzwvOUdbmxsUsXCR0pBA3BHiB+L/MKF1X68Ig1y8jyHVLzwQaLom8Xd43j8WjYZn+cegIqn8SWGNEBQmQ5Y48DI8+o4TNTE+qvsUitF1qQa3ct4nJThz5D/9MWMyuh4M7ul6Vwgd0NqrX29k3NlRY5+sAH7P83Ct6/+aTXjRtLVTY6gzlzJi4UzEiZJUacYVa4WNloLJFunacQ== root@wpo.wpo-nexus.bigscoots.com >> ~/.ssh/authorized_keys

echo "# Office 1 - BigScoots.com" >> ~/.ssh/authorized_keys
echo ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAgEAn+cOO+QgKiuntfsPmJ8NtUsGNmOlT3LKjRhR3Yk9paGYul/f+A0wP0YBp/ANpNPUeKO7TqTnyzL8PIpCUXOyJ5Nsoo2X3Bv2jERXj54qzX5BD8cDwLJ8ACIIy9O0tmG9vycAqE0JApEsgfeUN8NVe3uaVhdjfPZMgGhBZZvZavFFqdRkeDcLXhw+fuBQpN3inELYU2YVeR6XOYcavU0zFAC7zbhaS3x71xmXHfyVueJRsBUzrFu56Yag4XrcIopvoGy2SHX929SG34wa5tCtfpdkinxJpru/9fmKKJKMMEW49VS0cOC2dFjm67zR+RoTsyhG6QCLPIPwjDJry9JZ3bZ4YI74J+TXsjB7b1k33Vqcd2hIVJ3phhcWQiQ8sfoUMZQfWr6F1s1+Q2N+8G7l6rdMheLemzqH+ZKFC0QxhNei4qLFVDfVds7HnODn7V7kaG07ge0usN9P604vgVp33mtD0dsOzNAW21EBTjurDIu/akbYqUBBPPhDvlWotYylY9+o6rQyyVtrcBARr3mbAkZdrIpjLyOlXb/ZoLzl3b1ciBV+WmwaJwdYzQqiXDCz4W8zH4RwJFaBa6StPlF7Xau6g1Dnzd2UjtUmft+ciQNHzPqUnwG4V41kvqu3hhM8usGlSMGUa8wX1RWj/ZkpuMOeaamBzVbaIbn9UsKuBhk= rsa-key-20161116 >> ~/.ssh/authorized_keys

echo "# Office 2 - BigScoots.com" >> ~/.ssh/authorized_keys
echo ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAgEAx/wguQjxQ/h3JD6Tit6hHvXZFszRnQQMMVOEIvn0WUxk1+O6VSKu1soc9E+gLg1PK8tUesgFyluRAjewyR8JTbBiP5ZCDddt2wyuBV8qEtJV7og96gzqABp28CY54f0ER8JBF7dtB1cjawliL0CquiJnBhWO4Q4VbBTr/EXZghPtWJKHGBwX7ziZKxcsSpJfrCbYbU1caUkOjkHSNdnKX6KhHK6pCaL8b27sDBwqZrv+YGfheQXnXjiEGW8/oJ8mSP6mawVlxFocGCZtfrjKsr5zDREalLmOAdXsFw/evID95tqyRZt4V5eirvtCA5P1N7+6oTDJ2XvCkjUtHSrzHXXZ5z6UkTJqCaqC3bRVbxVRkFWjxYqLBZe8YTBzwOoUXVhP2kYPxz97hKhblhHWpO5R1GtT0ragVdjeXxtLWgs2eTqmGQat4x4PxeEAUOjxeY48UBMRG50XCHkdVylZrgwaDBr1IV3lCZc8BtDJKT1QKygIZkHVQfaqfvtQ1oFB6Nx5SNzJ7mHvmIQvaj+tWSOTBdIny6DO2RhPCJBz3UNUDUuul9mw1j5Gsv0VvudFDz4DxOjGUlk519KoeNyRvBuDRwVb51HUGX/4lykHfaG7KMmy6V35JGEzna4Voy6VVQr2xp2eNYlbw15UcFfA1BXRWaPmYiNGeDXvWn8QZ/k= rsa-key-20170802 >> ~/.ssh/authorized_keys

echo "# Office 3 - BigScoots.com" >> ~/.ssh/authorized_keys
echo ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAgEAjOtX/QuK+gv+yxQRvCRe3gFDvCR3qmjByRAbDq8I3FKBNLMUpDARMea8ISR/D/xgD1s30WWCXTtUQK9Qem0XSYSn9qdaKp30f7j5APfoL8bAect0i4XR/RpJBTbuH1Mt1WMaqKB5w8cuo7Rwo3dRE7iUZKlSjJFpofQ+hKAWFdnu82MgmetzbQtvR2Ta1ymLul2LK3bluy0tovyB4cWEFGFUwayK999tEvXJ3+T3PxEonVSUS2Ay3xfXJwK+yIigU/MQqf72bKlMRhGEuLnozlYwm5y97qJFKPIDSp4YN8ztmBeKLTBvQkSD32HctxKY4z2BzTev7Ip1Xhil6DDPY7Y/PoQwQ+xBP6jk6OpJud5P49lHIT16obkSW9L8fD5SHT+Ov7AJv0/cclY2VBbJBPKjCy5q+qeiVMSbGkAcRLp40UTTtWkFP6nmWjfPK1sytco5dy1GhoC6mwPrwLmq+mvMpa721NVpcw25/G7o7zXBXZ56i/7ImqlqwCa4/VNEioabhvM3zODLOfbqDXMeZVwIOAoshmAhGYLCm/+OdTi+J+D0+ub6k7EVze3h5/0c4rDYOib62Urp/G3ZUDSakLUj8KhyNLc5UaFbfQPD5ePiw2KQ9qO83Ikkt90oHjFQwW+vu8ribYgEsR/0qk8qTjFL8GYXRsRmqJaMyRFz18U= rsa-key-20170802 >> ~/.ssh/authorized_keys

echo "# Office 4 - BigScoots.com" >> ~/.ssh/authorized_keys
echo ssh-dss AAAAB3NzaC1kc3MAAACBAIYT7sboqZESdMYMCTti3TU7YxFTKlBTsYW0cpB+KnGSRN3pWBg7UuGqagtsA8Kjy7x0UC4n+xBT4qplIsfnO0xGAtYoQfC24R4CRgxzVK78SUx9SaBWEzC4SAhq8GF4rizCVQyAtUjTe7YYGliAVtQ+VhnsOopobJ7QTq9OPwbjAAAAFQDuwQe/Czor8p1a67LKvb4xdpBdmwAAAIAbE8p5D/7G7epAFi/c6SIAgQSi4HccXfVu2jGqJwhW3fr1kGsfigDmsu83vSDbnb++GU1ZfuhtrjDyHGReSR3A8nTrLhNWQWrCh9qiEqk+y1SsRksEAo+OAMkj1HyagU5oV5wBAYHS3uqp6irY8gBV7tOdRTeGT1LChT+Sx++BWQAAAIBHa1gvHIrWC03bmLAc52yMFlWSy9mRrdcUQ0qB9dnThSN7ReRHM7Bo1kbK8BrFXpNl5yLXCjLLwrCPe1e71z5gMRwCept8PPjFyX4BNlRYtj1Ox2LiePTHgMCnSYeyL1KRwEWhKRsYA2K8pdpoMs1KKwIB1c08jkegt1mqtpezZw== tim@localhost.localdomain >> ~/.ssh/authorized_keys

echo "# Office 5 - BigScoots.com" >> ~/.ssh/authorized_keys
echo ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDhD+XoZMHAXrpcR8MBtR7SGCe4Ii5G/PIKhKt/0RviOmF8yLJ3k8/ePmhA00QFM0DIRycgu0EatAYbzbrv9opJq8BMIaP2mpIbIrHZHwsIUKmoXCTcTu9ogOAp1Ke6pBIDYWA68dT62qRs05GJ9eRFRWBz6ymRKLlsEYFUS90nb3cH97cd+ILZv3qEGGC0nyPeoXVcX5MlmIU/S74ldNvvi0yo1UEH9/sKcc25wzKWQ0dzzGp5lpex4075NlrhlrMWysfe05XKKNYuDf3A7FSwMsgsFl5fVRbHCwqq3U1pb0RoNcWuzV5L33bLgpE57+RY403vVL3BMgbMNQfJ4io5 bassu@Thunderstorm >> ~/.ssh/authorized_keys

chmod 700 ~/.ssh ; chmod 600 ~/.ssh/authorized_keys

sed -ie 's/#Port.*[0-9]$/Port 2222/gI' /etc/ssh/sshd_config
sed -i 's/#UseDNS yes/UseDNS no/g' /etc/ssh/sshd_config
sed -i 's/#PermitRootLogin yes/PermitRootLogin without-password/g' /etc/ssh/sshd_config

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

sed -i 's/return 302/#return 302/g' /usr/local/nginx/conf/conf.d/phpmyadmin_ssl.conf
sed -i 's/#include \/usr\/local\/nginx\/conf\/php.conf/include \/usr\/local\/nginx\/conf\/php.conf/g' /usr/local/nginx/conf/conf.d/phpmyadmin_ssl.conf

npreload

sleep 2
echo "nginx install for $HOSTNAME completed" | mail -s "nginx install for $HOSTNAME completed" monitor@bigscoots.com
