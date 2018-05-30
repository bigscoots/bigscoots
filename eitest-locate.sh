#!/bin/bash

# https://laskowski-tech.com/2018/04/19/cleaning-up-after-eitest/
# Created: 2018-04-16
# Updated: 2018-04-23
#
# Purpose: Eitest investigation script
#

# Watch for connections to sinkhole
sinkhole="192.42.116"

# Repeat in loop until you stop the script
while true; do
 connect=$(netstat -tpn | grep $sinkhole);

# If connection found then capture data
 if [[ $connect ]]; then

# Get pid from connection
 PID=$(echo $connect | awk '{print$7}' | cut -d '/' -f1);

# Strace pid
 (strace -yrTfs 1024 -e trace=sendto,connect,open,write -o eitest-trace-$PID.out -p $PID &)

# Get open files from lsof
 (lsof -p $PID > eitest-files-$PID.log &)

# Log some basic info about the connection and process
 ps aux | awk "(\$2 ~ /$PID/)"'{print $0}' >> eitest-connection-log.txt;
 echo $connect >> eitest-connection-log.txt;
 fi

sleep 0.01
done
