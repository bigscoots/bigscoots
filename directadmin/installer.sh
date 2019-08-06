#!/bin/bash

/bigscoots/includes/keymebatman.sh

yum clean all
yum -y update

yum install -y wget gcc gcc-c++ flex bison make bind bind-libs bind-utils openssl openssl-devel perl quota libaio \
libcom_err-devel libcurl-devel gd zlib-devel zip unzip libcap-devel cronie bzip2 cyrus-sasl-devel perl-ExtUtils-Embed \
autoconf automake libtool which patch mailx bzip2-devel lsof glibc-headers kernel-devel expat-devel psmisc net-tools systemd-devel libdb-devel perl-DBI perl-Perl4-CoreLibs xfsprogs rsyslog logrotate crontabs file kernel-headers

cd /root
echo 2.0 > /root/.custombuild
wget -O setup.sh http://www.directadmin.com/setup.sh
chmod 755 setup.sh
IP=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1' | grep -v '192.168.')
ETH=$(ip addr |grep ${IP} | grep -o '[^ ]\+$')
read -p "Enter DA LID: " LID

./setup.sh 31392 ${LID} ${HOSTNAME} venet0:0 ${IP}

# Upgrade mysql to mariadb10.3

cd /usr/local/directadmin/custombuild
./build update
./build set mariadb 10.3
./build set mysql_inst mariadb
./build mariadb
./build php n


# openlitespeed
# ./build set mod_ruid2 no
# ./build set webserver openlitespeed
# ./build set php1_mode lsphp
# ./build openlitespeed
# ./build php n
# ./build rewrite_confs

# increase max userlength
sed -i '/max_username_length/c\max_username_length = 30' /usr/local/directadmin/conf/directadmin.conf
# enable sni
grep -q 'enable_ssl_sni=1' /usr/local/directadmin/conf/directadmin.conf || echo 'enable_ssl_sni=1' >> /usr/local/directadmin/conf/directadmin.conf

# enable LE
grep -q 'letsencrypt=1' /usr/local/directadmin/conf/directadmin.conf || echo 'letsencrypt=1' >> /usr/local/directadmin/conf/directadmin.conf

echo "action=directadmin&value=restart" >> /usr/local/directadmin/data/task.queue; /usr/local/directadmin/dataskq d2000
cd /usr/local/directadmin/custombuild
./build rewrite_confs
cd /usr/local/directadmin/custombuild
./build update
./build letsencrypt

# issue LE SSL for hostname

# /usr/local/directadmin/scripts/letsencrypt.sh request $(hostname -f)

# supposely enables LE SSL and issues SSL for all domains - unable to test

# cd /root
# wget -O autoletsencrypt.sh http://files.directadmin.com/services/all/letsencrypt/autoletsencrypt.sh
# chmod 755 autoletsencrypt.sh
# ./autoletsencrypt.sh

# change da port

sed -i 's/port=2222/port=4444/g' /usr/local/directadmin/conf/directadmin.conf
/bin/systemctl restart directadmin.service

# wp-cli

wget -O /usr/local/sbin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar ; chmod +x /usr/local/sbin/wp
ln -s /usr/local/sbin/wp /usr/sbin/wp
echo "alias wp='/usr/local/bin/php /usr/local/sbin/wp --allow-root'" >> /root/.bashrc


# Migration:

# mkdir -p /home/all_backups
# for user in `ls /var/cpanel/users/`; do { /scripts/pkgacct ${user} /home/all_backups; }; done
# rsync -avtP --delete /home/all_backups/ 23.29.145.27:/home/admin/all_backups/
# echo "" | mail -s "Finished migrating all cpanel accounts to 23.29.145.77:/home/admin/admin_backups/" monitor@bigscoots.com
