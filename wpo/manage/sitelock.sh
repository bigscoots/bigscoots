#!/bin/bash

# add htpasswd protection


if [[ ! $1 =~ (on|off) ]]; then
  echo "1 was set to  $1" | mail -s "WPO - sitelock.sh fail - on/off not specified  -  $HOSTNAME" monitor@bigscoots.com
  exit
fi

if [ -z "$2" ]; then
    echo "" | mail -s "WPO - sitelock.sh fail - domain not specified  -  $HOSTNAME" monitor@bigscoots.com
    exit
fi

domain="$2"

# /bigscoots/wpo/manage/sitelock.sh off domain.com

if [[ $1 == off ]]; then

    if  ! grep -q wpolocksite /usr/local/nginx/conf/conf.d/"$domain".ssl.conf; then
        exit 0
    fi

    if grep -q "\#auth_basic_user_file /home/nginx/domains/"$domain"/wpolocksite" /usr/local/nginx/conf/conf.d/"$domain".ssl.conf; then
        exit 0
    fi

    if ! grep -q "\#auth_basic_user_file /home/nginx/domains/"$domain"/wpolocksite" /usr/local/nginx/conf/conf.d/"$domain".ssl.conf; then
        sed -i "s=auth_basic_user_file /home/nginx/domains/$domain/wpolocksite=#auth_basic_user_file /home/nginx/domains/$domain/wpolocksite=g" /usr/local/nginx/conf/conf.d/"$domain".ssl.conf
    fi
fi


if [[ $1 == on ]]; then

    if [ -z "$3" ]; then
    echo "" | mail -s "WPO - sitelock.sh fail - username not specified  -  $HOSTNAME" monitor@bigscoots.com
    exit
    fi

    if [ -z "$4" ]; then
    echo "" | mail -s "WPO - sitelock.sh fail - password not specified  -  $HOSTNAME" monitor@bigscoots.com
    exit
    fi

# /bigscoots/wpo/manage/sitelock.sh on domain.com user pass

    if  ! grep -q wpolocksite /usr/local/nginx/conf/conf.d/"$domain".ssl.conf ; then

    /usr/local/nginx/conf/htpasswd.sh create /home/nginx/domains/"$domain"/wpolocksite "$3" "$4" > /dev/null 2>&1
    sed -i "/location \/ {/a \  auth_basic_user_file /home/nginx/domains/$domain/wpolocksite;" /usr/local/nginx/conf/conf.d/"$domain".ssl.conf
    sed -i "/location \/ {/a \  auth_basic \"Private\"; #wpolocksiteauthbasic" /usr/local/nginx/conf/conf.d/"$domain".ssl.conf

    else
    sed -i "s=#auth_basic_user_file /home/nginx/domains/$domain/wpolocksite=auth_basic_user_file /home/nginx/domains/$domain/wpolocksite=g" /usr/local/nginx/conf/conf.d/"$domain".ssl.conf
    /usr/local/nginx/conf/htpasswd.sh create /home/nginx/domains/"$domain"/wpolocksite "$3" "$4" > /dev/null 2>&1

        if  ! grep -q '#wpolocksiteauthbasic' /usr/local/nginx/conf/conf.d/"$domain".ssl.conf ; then
            echo "Make sure to add the comment #wpolocksiteauthbasic to the end of the existing auth_basic in the / Location block and uncomment the begining of  auth_basic... Ask Justin if you are not sure." | mail -s "WPO Enable Sitelock check -  $domain -  $HOSTNAME" monitor@bigscoots.com
        else
            sed -i 's/#auth_basic "Private"; #wpolocksiteauthbasic/auth_basic "Private"; #wpolocksiteauthbasic/g' /usr/local/nginx/conf/conf.d/"$domain".ssl.conf
        fi

    fi

fi


nginx -t > /dev/null 2>&1
if [ $? -eq 0 ]; then
npreload > /dev/null 2>&1
else
nginx -t 2>&1 | mail -s "WPO URGENT - Nginx conf fail while enabling/disabling htpasswd protection -  $HOSTNAME" monitor@bigscoots.com
exit 1
fi