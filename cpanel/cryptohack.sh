#!/bin/bash

if ps aux|grep "./cron.php -e0.0.0.0 -p" |grep -v grep > /dev/null 2>&1 ; then
 PIDHACK=$(ps aux|grep "./cron.php -e0.0.0.0 -p" |grep -v grep| awk '{print $2}' | head -1)
 lsof -p "${PIDHACK}" > /root/tmpdtshack.txt
 kill -9  "${PIDHACK}"
 cat /root/tmpdtshack.txt | mail -s "infected account  $HOSTNAME process in ticket" monitor@bigscoots.com
fi
