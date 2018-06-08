#!/bin/sh


log="/var/tmp/du.log"

df -h > /tmp/du$$

while read line
do
    fields=`echo $line | awk '{print NF}'`
    case $fields in
    5) echo $line | awk '{print $5,$4}' >> $log;;
    6) echo $line | awk '{print $6,$5}' >> $log;;
    esac
done < /tmp/du$$

cat "/var/tmp/du.log" | while read -r output;
do
  usep=$(echo "$output" | awk '{ print $2}' | cut -d'%' -f1  )
  partition=$(echo "$output" | awk '{ print $1 }' )
  if [ "$usep" -ge 90 ]; then
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

rm /tmp/du$$ /var/tmp/du.log
