#!/bin/bash

# add htpasswd protection
# /bigscoots/wpo/manage/htpasswd.sh domain.com user pass

if  ! grep -q wpolocksite /usr/local/nginx/conf/conf.d/"$1".ssl.conf ; then

/usr/local/nginx/conf/htpasswd.sh create /home/nginx/domains/"$1"/wpolocksite "$2" "$3"
sed -i "/location \/ {/a \  auth_basic_user_file /home/nginx/domains/$1/wpolocksite;" /usr/local/nginx/conf/conf.d/"$1".ssl.conf
sed -i "/location \/ {/a \  auth_basic \"Private\";" /usr/local/nginx/conf/conf.d/"$1".ssl.conf

echo "htpasswd applied"
        echo
        echo

        sleep 1

else

/usr/local/nginx/conf/htpasswd.sh create /home/nginx/domains/"$1"/wpolocksite "$2" "$3"

        echo "htpasswd applied"
        echo
        echo

        sleep 1

fi

    nginx -t > /dev/null 2>&1
    if [ $? -eq 0 ]; then
                npreload > /dev/null 2>&1
        else
                nginx -t 2>&1 | mail -s "WPO URGENT - Nginx conf fail while adding htpasswd protection -  $HOSTNAME" monitor@bigscoots.com
                exit 1
    fi
