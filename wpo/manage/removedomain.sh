#!/bin/bash

if [ -z "$1" ]; then
  echo "Requires a domain."
  exit
fi

DOMAIN="$1"
DOMAINSTAGING=$(echo "$DOMAIN" | sed 's/\.//g ; s/$/.bigscoots-staging.com/')
WPCLIFLAGS="--allow-root --skip-plugins --skip-themes --require=/bigscoots/includes/err_report.php"

if [ ! -s /root/tools/wp_uninstall_"$DOMAIN".sh ]; then
	rm -rf /usr/local/nginx/conf/conf.d/"$DOMAIN".conf
	rm -rf /usr/local/nginx/conf/conf.d/"$DOMAIN".ssl.conf
	rm -rf /home/nginx/domains/"$DOMAIN"
	rm -rf /root/tools/wp_updater_"$DOMAIN".sh
	rm -rf /usr/local/nginx/conf/ssl/"$DOMAIN"
	rm -rf /usr/local/nginx/conf/wpincludes/"$DOMAIN"
	crontab -l > cronjoblist
	sed -i "/wp_updater_$DOMAIN.sh/d" cronjoblist
	sed -i "/\/$DOMAIN\/wp-cron.php/d" cronjoblist
	crontab cronjoblist
	rm -rf cronjoblist
	npreload
else
	/root/tools/wp_uninstall_"$DOMAIN".sh <<< y
fi

sleep 5

if [ "$2" == fresh ]; then
  /bigscoots/wpo/manage/createdomain.sh "$DOMAIN" fresh
fi

if [ "$2" == permanent ]; then
	if [ -d /home/nginx/domains/"$DOMAINSTAGING" ]; then
  		if [ ! -s /root/tools/wp_uninstall_"$DOMAINSTAGING".sh ]; then
		  rm -rf /usr/local/nginx/conf/conf.d/"$DOMAINSTAGING".conf
		  rm -rf /usr/local/nginx/conf/conf.d/"$DOMAINSTAGING".ssl.conf
		  rm -rf /home/nginx/domains/"$DOMAINSTAGING"
		  rm -rf /root/tools/wp_updater_"$DOMAINSTAGING".sh
		  rm -rf /usr/local/nginx/conf/ssl/"$DOMAINSTAGING"
		  rm -rf /usr/local/nginx/conf/wpincludes/"$DOMAINSTAGING"
		  crontab -l > cronjoblist
		  sed -i "/wp_updater_$DOMAINSTAGING.sh/d" cronjoblist
		  sed -i "/\/$DOMAINSTAGING\/wp-cron.php/d" cronjoblist
		  crontab cronjoblist
		  rm -rf cronjoblist
		  npreload
		else
		  /root/tools/wp_uninstall_"$DOMAINSTAGING".sh <<< y
		fi
	  pure-pw list | grep /home/nginx/domains/"$DOMAINSTAGING" | awk '{print $1}' | while read -r ftpuser ; do pure-pw userdel $ftpuser >/dev/null 2>&1 ; done
	fi
  pure-pw list | grep /home/nginx/domains/"$DOMAIN" | awk '{print $1}' | while read -r ftpuser ; do pure-pw userdel $ftpuser >/dev/null 2>&1 ; done
fi