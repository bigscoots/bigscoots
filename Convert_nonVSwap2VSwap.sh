#!/bin/bash

# Usage single: /bigscoots/Convert_nonVSwap2VSwap.sh 123
# Usage all: for CT in $(vzlist -H -o ctid); /bigscoots/Convert_nonVSwap2VSwap.sh $CT ; done

CTID=$1
CURRENTMEM=$(vzctl exec $CTID free -m | grep Mem: | awk '{print $2}')
RAM="$(($CURRENTMEM / 1024))G"
SWAP="$(($CURRENTMEM / 1024 * 2))G"
CFG=/etc/vz/conf/${CTID}.conf

echo "CTID = $CTID"
echo "RAM = $RAM"
echo "SWAP = $SWAP"

cp $CFG $CFG.pre-vswap
grep -Ev '^(KMEMSIZE|LOCKEDPAGES|PRIVVMPAGES|SHMPAGES|NUMPROC|PHYSPAGES|VMGUARPAGES|OOMGUARPAGES|NUMTCPSOCK|NUMFLOCK|NUMPTY|NUMSIGINFO|TCPSNDBUF|TCPRCVBUF|OTHERSOCKBUF|DGRAMRCVBUF|NUMOTHERSOCK|DCACHESIZE|NUMFILE|AVNUMPROC|NUMIPTENT|ORIGIN_SAMPLE|SWAPPAGES)=' > $CFG <  $CFG.pre-vswap
vzctl set $CTID --ram $RAM --swap $SWAP --save
vzctl set $CTID --reset_ub

vzctl exec $CTID free -m
