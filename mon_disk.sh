#!/bin/sh
df -H | grep -vE '^Filesystem|tmpfs|cdrom|none' | awk '{ print $5 " " $1 }' | sort | uniq | while read -r output;
do
  usep=$(echo "$output" | awk '{ print $1}' | cut -d'%' -f1  )
  partition=$(echo "$output" | awk '{ print $2 }' )
  if [ "$usep" -ge 95 ]; then
    echo "Running out of space \"$partition ($usep%)\" on $(hostname) as on $(date)" |
     mail -s "Alert: Almost out of disk space $usep% on $HOSTNAME" monitor@bigscoots.com
  fi
done
