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

wp ${WPCLIFLAGS} user update "$id" --user_pass="$password" --path=/home/nginx/domains/"$domain"/public --skip-email

;;
add_admin)

# /bigscoots/wpo/manage/users.sh add_admin ${DOMAIN} ${USER} ${EMAIL}

user="$3"
email="$4"

wp ${WPCLIFLAGS} user create "$user" "$email" --role=administrator --porcelain --path=/home/nginx/domains/"$domain"/public

;;
del_admin)

# /bigscoots/wpo/manage/users.sh del_admin ${DOMAIN} ${USER} ${REASSIGN_ID}

user="$3"
reassign_id="$4"

wp ${WPCLIFLAGS} user delete "$user" --reassign="$reassign_id" --yes --path=/home/nginx/domains/"$domain"/public

;;
esac