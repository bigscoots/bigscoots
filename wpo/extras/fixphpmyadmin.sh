#!/bin/bash

# fixphpmyadmin.sh

shopt -s extglob

if grep "^cd /usr/local/nginx/html/" /root/tools/phpmyadmin_update.sh >/dev/null 2>&1; then
	$(grep "^cd /usr/local/nginx/html/" /root/tools/phpmyadmin_update.sh)
	if echo $(pwd) |grep -q /usr/local/nginx/html/*_mysqladmin*; then
		rm -rf !("config.inc.php")
		wget https://files.phpmyadmin.net/phpMyAdmin/5.0.1/phpMyAdmin-5.0.1-all-languages.zip
		unzip phpMyAdmin-5.0.1-all-languages.zip
		mv phpMyAdmin-5.0.1-all-languages/* .
		rm -rf phpMyAdmin-5.0.1-all-languages*
		chown -R nginx: .
		npreload
	fi
fi