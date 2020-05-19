#!/bin/bash

# fixphpmyadmin.sh

shopt -s extglob

if grep "^cd /usr/local/nginx/html/" /root/tools/phpmyadmin_update.sh >/dev/null 2>&1; then
	$(grep "^cd /usr/local/nginx/html/" /root/tools/phpmyadmin_update.sh)
	if echo $(pwd) |grep -q /usr/local/nginx/html/*_mysqladmin*; then
		rm -rf !("config.inc.php") 
		wget -q https://github.com/phpmyadmin/phpmyadmin/archive/STABLE.zip
		unzip STABLE.zip 
		mv phpmyadmin-STABLE/* . 
		rm -rf phpmyadmin-STABLE* 
		chown -R nginx: . >/dev/null 2>&1
		
		nginx -t > /dev/null 2>&1
    	if [ $? -eq 0 ]; then
                npreload > /dev/null 2>&1
        else
                nginx -t 2>&1 | mail -s "WPO URGENT - Nginx conf fail during phpmyadmin fix -  $HOSTNAME" monitor@bigscoots.com
                exit 1
   	    fi
	fi
fi
