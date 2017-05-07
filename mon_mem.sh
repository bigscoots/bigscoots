#!/bin/bash
used=$(free -m |awk 'NR==3 {print $3}')
total=$(free -m |awk 'NR==2 {print $2}')
result=$(echo "$used / $total" |bc -l)
result2=$(echo "$result > 0.8" |bc)

if [ "$result2" -eq 1 ];then
ps aux >> /tmp/ps.txt ; echo "$(hostname): more than 80% of ram used" | mail -s "$(hostname): more than 80% of ram used" monitor@bigscoots.com </tmp/ps.txt ; rm -f /tmp/ps.txt
fi
