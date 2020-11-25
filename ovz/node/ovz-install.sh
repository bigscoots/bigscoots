#!/bin/bash

# Openvz7 install

# New Server Install - BigScoots.com
# Install Tools and update system

yum -y install nano ntp mailx pciutils bind-utils traceroute nmap screen yum-utils net-tools dos2unix lshw python python-ctypes iotop ncurses-devel libpcap-devel gcc make wget curl unzip wget mailx git
yum -y update

sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config

setenforce 0
ntpdate pool.ntp.org
systemctl enable ntpd
systemctl start ntpd
sysctl -w net.ipv6.conf.default.disable_ipv6=0
sysctl -w net.ipv6.conf.all.disable_ipv6=0
sysctl -w vm.swappiness=0

cd /
git clone https://github.com/jcatello/bigscoots
/bigscoots/includes/keymebatman.sh

# Install iftop
wget http://www.ex-parrot.com/~pdw/iftop/download/iftop-0.17.tar.gz
tar xvfvz iftop-0.17.tar.gz
cd iftop-0.17
./configure
make
make install

mkdir -p /tmp/lsi
cd /tmp/lsi
wget --user=hetzner --password=download http://download.hetzner.de/tools/LSI/tools/MegaCLI/8.07.14_MegaCLI.zip
#wget -O /tmp/lsi/firmware.zip https://www.dropbox.com/s/zv6w50auu83nhyf/23-34-0-0017_SAS_2208_FW_IMAGE_APP_3-460-95-6434.zip
#wget -O /tmp/lsi/firmware.zip https://www.dropbox.com/s/xyuh7otfkpn13vf/23-34-0-0019_SAS_2208_FW_IMAGE_APP_3-460-115-6465.zip
#LSI MegaRAID SAS 9271-8i
#wget -O /tmp/lsi/firmware.zip https://docs.broadcom.com/docs-and-downloads/docs-and-downloads/docs-and-downloads/raid-controllers/raid-controllers-common-files/23-34-0-0019_SAS_2208_FW_IMAGE_APP_3-460-115-6465.zip
#wget -O /tmp/lsi/firmware.zip https://s3.amazonaws.com/uploads.hipchat.com/31137/205915/HY6FdV0teKX9c7E/12.15.0-0239_MR_2108_SAS_FW_2.130.403-4660.zip
#wget -O /tmp/lsi/firmware.zip https://s3.amazonaws.com/uploads.hipchat.com/31137/205915/OcuOgFkdgc28liX/12-15-0-0205_SAS_2108_Fw_Image_APP_2-130-403-3835.zip
#wget -O /tmp/lsi/firmware.zip https://s3.amazonaws.com/uploads.hipchat.com/31137/205915/eeLydEBtan0fcoc/fw_avago_hwr_9240_r510i_20.13.1-0254.zip
unzip *MegaCLI.zip
rpm -ivh *inux/MegaCli-*.noarch.rpm
ln -s /opt/MegaRAID/MegaCli/MegaCli64 /sbin/
ln -s /opt/MegaRAID/MegaCli/MegaCli64 /usr/local/sbin/
unzip /tmp/lsi/firmware.zip
MegaCli64 -adpfwflash -f mr*.rom -a0
cd ~ ; wget https://www.bigscoots.com/downloads/lsi.zip ; unzip lsi.zip
chmod +x lsi.sh
(crontab -l ; echo "0 * * * * ~/lsi.sh checkNemail") | crontab - .
rm -f /etc/cron.daily/raid
/opt/MegaRAID/MegaCli/MegaCli64 -LDSetProp -WT -Immediate -Lall -aAll
/opt/MegaRAID/MegaCli/MegaCli64 -LDSetProp -NORA -Immediate -Lall -aAll
/opt/MegaRAID/MegaCli/MegaCli64 -LDSetProp -Direct -Immediate -Lall -aAll

sed -ie 's/#Port.*[0-9]$/Port 2222/gI' /etc/ssh/sshd_config
sed -i 's/#UseDNS yes/UseDNS no/g' /etc/ssh/sshd_config
sed -i 's/#PermitRootLogin yes/PermitRootLogin without-password/g' /etc/ssh/sshd_config
service sshd restart

cd /bigscoots/
/bigscoots/includes/keymebatman.sh

echo 'QUOTAUGIDLIMIT="1"' >> /etc/vz/conf/ve-vswap-solus.conf-sample
sed -i '/DISKSPACE/c\DISKSPACE="20485760:20485760"' /etc/vz/conf/vps.vzpkgtools.conf-sample

wget https://www.dropbox.com/s/60csqc35sd9gjax/ovz-converter.txt -O /usr/libexec/ovz-template-converter
/usr/libexec/ovz-template-converter

yum install vzpkg* centos-7-x86_64-ez -y

mkdir -p /vz/template/cache
wget --no-check-certificate -O /vz/template/cache/centos-7-x86_64-wpov2.tar.gz http://208.117.38.205/ovz-temp/scoots/centos-7-x86_64-wpov2.tar.gz
wget --no-check-certificate -O /vz/template/cache/centos-7-x86_64-cpanelv1.tar.gz http://208.117.38.205/ovz-temp/scoots/centos-7-x86_64-cpanelv1.tar.gz

/usr/libexec/ovz-template-converter --verbose /vz/template/cache/centos-7-x86_64-wpov2.tar.gz
/usr/libexec/ovz-template-converter --verbose /vz/template/cache/centos-7-x86_64-cpanelv1.tar.gz

wget -O /root/install.sh https://files.soluslabs.com/install.sh
bash /root/install.sh <<EOF
1
EOF