#!/bin/bash

yum clean all

yum -y install git nano ntp mailx pciutils bind-utils traceroute nmap screen yum-utils net-tools dos2unix lshw python python-ctypes iotop ncurses-devel libpcap-devel gcc make wget curl
yum -y update

# Disabale SELinux and Configure time
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
setenforce 0
chkconfig ntpd on
ntpdate pool.ntp.org
/etc/init.d/ntpd start

sysctl -w net.ipv6.conf.default.disable_ipv6=0
sysctl -w net.ipv6.conf.all.disable_ipv6=0

systemctl stop firewalld.service
systemctl disable firewalld.service
systemctl set-default multi-user.target

if [ -f /etc/selinux/config ]; then
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config && setenforce 0
sed -i 's/SELINUX=permissive/SELINUX=disabled/g' /etc/selinux/config && setenforce 0
fi

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
          wget https://docs.broadcom.com/docs-and-downloads/raid-controllers/raid-controllers-common-files/8-07-14_MegaCLI.zip
          unzip ./*MegaCLI.zip
          rpm -ivh ./*inux/MegaCli-*.noarch.rpm
          ln -s /opt/MegaRAID/MegaCli/MegaCli64 /sbin/
          ln -s /opt/MegaRAID/MegaCli/MegaCli64 /usr/local/sbin/
          cd ~ || exit ; wget https://www.bigscoots.com/downloads/lsi.zip ; unzip lsi.zip
          chmod +x lsi.sh
          (crontab -l ; echo "0 * * * * ~/lsi.sh checkNemail") | crontab - .
          rm -f /etc/cron.daily/raid
          /opt/MegaRAID/MegaCli/MegaCli64 -LDSetProp -WT -Immediate -Lall -aAll
          /opt/MegaRAID/MegaCli/MegaCli64 -LDSetProp -NORA -Immediate -Lall -aAll
          /opt/MegaRAID/MegaCli/MegaCli64 -LDSetProp -Direct -Immediate -Lall -aAll
        fi
fi

# Install iftop
wget http://www.ex-parrot.com/~pdw/iftop/download/iftop-0.17.tar.gz
tar xvfvz iftop-0.17.tar.gz
cd iftop-0.17
./configure
make
make install

if [ -f /etc/selinux/config ]; then
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config && setenforce 0
sed -i 's/SELINUX=permissive/SELINUX=disabled/g' /etc/selinux/config && setenforce 0
fi

git clone https://github.com/jcatello/bigscoots /bigscoots
bash /bigscoots/includes/keymebatman.sh

if [ $1 = shared ]; then
  bash /bigscoots/cpanel/installer_shared.sh
else
  bash /bigscoots/bsi2-dedi.sh
fi
