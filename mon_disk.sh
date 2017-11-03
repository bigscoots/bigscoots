#!/bin/sh
df -H | grep -vE '^Filesystem|tmpfs|cdrom|none' | awk '{ print $5 " " $1 }' | sort | uniq | while read -r output;
do
  usep=$(echo "$output" | awk '{ print $1}' | cut -d'%' -f1  )
  partition=$(echo "$output" | awk '{ print $2 }' )
  if [ "$usep" -ge 95 ]; then
    (
        echo "Hello,"
        echo "Your server is currently using ($usep%) of its available disk space."
        echo "Please try and free up space or see about upgrading to the next package to increase your available disk space."
        echo "You can also reply back to this email to open a support ticket to request assistance."
        echo ""
        echo "Regards"
        echo "The Bigscoots Team"
        echo ""
        echo ""
        echo "Automated Response $(date)"

     ) | mail -s "BigScoots Alert: Almost out of disk space $usep% -  $(hostname)" -S replyto="support@bigscoots.com" monitor@bigscoots.com
  fi
done
