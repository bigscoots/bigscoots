#!/bin/bash

# fixphpmyadmin.sh

shopt -s extglob

if grep "^cd /usr/local/nginx/html/" /root/tools/phpmyadmin_update.sh >/dev/null 2>&1; then
	$(grep "^cd /usr/local/nginx/html/" /root/tools/phpmyadmin_update.sh)
	if echo $(pwd) |grep -q /usr/local/nginx/html/*_mysqladmin*; then
		rm -rf !("config.inc.php")
		wget https://github.com/phpmyadmin/phpmyadmin/archive/STABLE.zip
		unzip STABLE.zip
		mv phpmyadmin-STABLE/* .
		rm -rf phpmyadmin-STABLE*
		chown -R nginx: .
		npreload
	fi
fi
