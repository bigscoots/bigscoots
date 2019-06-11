#!/bin/bash

if [ -z "$1" ]
then
      echo "" | mail -s "PXE Dedi Install - done $HOSTNAME -  $ipaddr - failed no IP found." monitor@bigscoots.com
      exit
fi

ipaddr=$1

if [[ "$ipaddr" == *.1 ]]
then
      echo "" | mail -s "PXE Dedi Install - $HOSTNAME Network setup failed - The IP ends in .1 VERY BAD, check conf." monitor@bigscoots.com
      exit
fi

if [[ $ipaddr == *"50.31.98"* ]] || [[ $ipaddr == *"50.31.99"* ]] ; then

ipgateway=50.31.98.1
ipnetmask=252.255.254.0

else

ipgateway=$(awk -F"." '{print $1"."$2"."$3".1"}'<<<"$ipaddr")
ipnetmask=255.255.255.0

fi

{
echo alias bond0 bonding
echo options bond0 miimon=100 mode=0 lacp_rate=1
} >> /etc/modprobe.d/bonding.conf


sed -i 's/^/#/' /etc/sysconfig/network-scripts/ifcfg-eth0
sed -i 's/^/#/' /etc/sysconfig/network-scripts/ifcfg-eth1

{
echo
echo DEVICE=eth0
echo TYPE=Ethernet
echo ONBOOT=yes
echo NM_CONTROLLED=no
echo MASTER=bond0
echo SLAVE=yes
} >> /etc/sysconfig/network-scripts/ifcfg-eth0

{
echo
echo DEVICE=eth1
echo TYPE=Ethernet
echo ONBOOT=yes
echo NM_CONTROLLED=no
echo MASTER=bond0
echo SLAVE=yes
} >> /etc/sysconfig/network-scripts/ifcfg-eth1


# ifcfg-bond0

{
echo DEVICE=bond0
echo IPADDR="$ipaddr"
echo NETMASK="$ipnetmask"
echo GATEWAY="$ipgateway"
echo TYPE=Bond
echo ONBOOT=yes
echo NM_CONTROLLED=no
echo BOOTPROTO=static
echo DNS1=1.1.1.1
echo DNS2=1.0.0.1
} >> /etc/sysconfig/network-scripts/ifcfg-bond0
