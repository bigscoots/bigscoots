#!/bin/bash

if [ -z "$1" ]; then
  echo "Requires a domain."
  exit
fi

DOMAIN="$1"
WPCLIFLAGS="--allow-root --skip-plugins --skip-themes --require=/bigscoots/includes/err_report.php"

if [ ! -s /root/tools/wp_uninstall_"$DOMAIN".sh ]; then
	rm -rf /usr/local/nginx/conf/conf.d/"$DOMAIN".conf
	rm -rf /usr/local/nginx/conf/conf.d/"$DOMAIN".ssl.conf
	rm -rf /home/nginx/domains/"$DOMAIN"
	rm -rf /root/tools/wp_updater_"$DOMAIN".sh
	rm -rf /usr/local/nginx/conf/ssl/"$DOMAIN"
	rm -rf /usr/local/nginx/conf/wpincludes/"$DOMAIN"
	crontab -l > cronjoblist
	sed -i "/wp_updater_mydedicatedservers.com.sh/d" cronjoblist
	sed -i "/\/mydedicatedservers.com\/wp-cron.php/d" cronjoblist
	crontab cronjoblist
	rm -rf cronjoblist
	pure-pw userdel mydedicatedserverscom >/dev/null 2>&1
	npreload
else
	/root/tools/wp_uninstall_"$DOMAIN".sh <<< y
fi

sleep 5

if [ "$2" == fresh ]; then
  /bigscoots/wpo/manage/createdomain.sh "$DOMAIN" fresh
fi