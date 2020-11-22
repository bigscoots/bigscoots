#!/bin/bash

if [ -z "$1" ]
then
      echo "" | mail -s "PXE OVZ Install - done $HOSTNAME -  $ipaddr - failed no IP found." monitor@bigscoots.com
      exit
fi

ipaddress=$1

if [[ "$ipaddress" == *.1 ]]
then
      echo "" | mail -s "PXE OVZ Install - $HOSTNAME Network setup failed - The IP ends in .1 VERY BAD, check conf." monitor@bigscoots.com
      exit
fi

if [[ $ipaddress == *"50.31.98"* ]] || [[ $ipaddress == *"50.31.99"* ]] ; then
	ipgateway=50.31.98.1
	ipnetmask=255.255.254.0
elif [[ $ipaddress == *"216.185.21"* ]]; then
	ipgateway=216.185.212.1
	ipnetmask=255.255.252.0
else
	ipgateway=$(awk -F"." '{print $1"."$2"."$3".1"}'<<<"$ipaddress")
	ipnetmask=255.255.255.0
fi

{
echo alias bond0 bonding
echo options bond0 miimon=100 mode=0 lacp_rate=1
} >> /etc/modprobe.d/bonding.conf


cp -rf /etc/sysconfig/network-scripts /etc/sysconfig/network-scripts.bk
cd /etc/sysconfig/network-scripts/

sed -i 's/^/#/' /etc/sysconfig/network-scripts/ifcfg-eth0 /etc/sysconfig/network-scripts/ifcfg-eth1 /etc/sysconfig/network-scripts/ifcfg-br0

{
echo DEVICE=bond0
echo BRIDGE=br0
echo TYPE=Bond
echo ONBOOT=yes
echo NM_CONTROLLED=no
} >> /etc/sysconfig/network-scripts/ifcfg-bond0

{
echo 
echo DEVICE=eth0
echo ONBOOT=yes
echo NM_CONTROLLED=no
echo MASTER=bond0
echo SLAVE=yes
} >> /etc/sysconfig/network-scripts/ifcfg-eth0

{
echo 
echo DEVICE=eth1
echo ONBOOT=yes
echo NM_CONTROLLED=no
echo MASTER=bond0
echo SLAVE=yes
} >> /etc/sysconfig/network-scripts/ifcfg-eth1

{
echo 
echo DEVICE="br0"
echo ONBOOT=yes
echo NETBOOT=yes
echo IPV6INIT=yes
echo ONBOOT=yes
echo NM_CONTROLLED=no
echo IPADDR="$ipaddress"
echo NETMASK="$ipnetmask"
echo GATEWAY="$ipgateway"
echo DNS1=1.1.1.1
echo DNS2=1.0.0.1
echo DEFROUTE=yes
echo IPV4_FAILURE_FATAL=no
echo IPV6_AUTOCONF=yes
echo IPV6_DEFROUTE=yes
echo IPV6_PEERDNS=yes
echo IPV6_PEERROUTES=yes
echo IPV6_FAILURE_FATAL=no
echo IPV6_PRIVACY=no
echo TYPE="Bridge"
echo DELAY="2"
echo STP="off"
} >> /etc/sysconfig/network-scripts/ifcfg-br0

sed -i 's/#HWADDR/HWADDR/g' /etc/sysconfig/network-scripts/ifcfg-eth0 /etc/sysconfig/network-scripts/ifcfg-eth1
sed -i 's/#UUID/UUID/g' /etc/sysconfig/network-scripts/ifcfg-eth0 /etc/sysconfig/network-scripts/ifcfg-eth1 /etc/sysconfig/network-scripts/ifcfg-br0