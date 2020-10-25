#!/bin/bash

until ! ps aux|grep "./cron.php -e0.0.0.0 -p" |grep -v grep > /dev/null 2>&1; do
	PIDHACK=$(ps aux|grep "./cron.php -e0.0.0.0 -p" |grep -v grep| awk '{print $2}' | head -1)
	PIDUSER=$(ps -o uname= -p "${PIDHACK}")
	echo "cPanel User: ${PIDUSER}" > /root/tmpdtshack.txt
	echo "PID Info:" >> /root/tmpdtshack.txt
	echo "---------------------------" >> /root/tmpdtshack.txt
	/usr/sbin/lsof -p "${PIDHACK}" >> /root/tmpdtshack.txt
	echo "---------------------------" >> /root/tmpdtshack.txt
	kill -9  "${PIDHACK}"
	cat /root/tmpdtshack.txt | mail -s "$HOSTNAME - cPanel User: ${PIDUSER} infected -  info in ticket." monitor@bigscoots.com
done