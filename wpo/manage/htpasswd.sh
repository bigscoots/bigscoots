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
