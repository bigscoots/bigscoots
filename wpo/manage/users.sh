#!/bin/bash

domain="$2"
WPCLIFLAGS="--allow-root --skip-plugins --skip-themes --require=/bigscoots/includes/err_report.php"


case $1 in
list_admins)

# /bigscoots/wpo/manage/users.sh list_admins ${DOMAIN}

wp ${WPCLIFLAGS} user list --role=administrator --fields=ID,user_login,user_email,user_registered --format=json --path=/home/nginx/domains/"$domain"/public

;;
change_email)

# /bigscoots/wpo/manage/users.sh change_email ${DOMAIN} ${ID} ${EMAIL}

id="$3"
email="$4"

wp ${WPCLIFLAGS} user update "$id" --user_email="$email" --path=/home/nginx/domains/"$domain"/public

;;
change_password)

# /bigscoots/wpo/manage/users.sh change_password ${DOMAIN} ${ID} ${PASSWORD}

id="$3"
password="$4"

wp ${WPCLIFLAGS} user update "$id" --user_pass="$password" --path=/home/nginx/domains/"$domain"/public

;;
esac