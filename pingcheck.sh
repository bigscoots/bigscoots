#!/bin/bash

ping_targets="int-backup2.bigscoots.com"
failed_hosts=""

for i in $ping_targets
do
   ping -c 1 $i > /dev/null
   if [ $? -ne 0 ]; then
      if [ "$failed_hosts" == "" ]; then
         failed_hosts="$i"
      else
         failed_hosts="$failed_hosts, $i"
      fi
   fi
done

if [ "$failed_hosts" != "" ]; then
   echo $failed_hosts| mailx -s "Failed ping targets" monitor@bigscoots.com
fi
