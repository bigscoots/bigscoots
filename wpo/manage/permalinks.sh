#!/bin/bash

WPCLIFLAGS="--allow-root --skip-plugins --skip-themes --require=/bigscoots/includes/err_report.php"
DOMAIN=$2

case $1 in
permalinks_curent)

# /bigscoots/wpo/manage/permalinks.sh permalinks_curent ${DOMAIN}

wp ${WPCLIFLAGS} option get permalink_structure --path=/home/nginx/domains/"${DOMAIN}"/public

;;
permalinks_remove)

# /bigscoots/wpo/manage/permalinks.sh permalinks_remove ${DOMAIN}

PERMALINKS=$(wp ${WPCLIFLAGS} option get permalink_structure --path=/home/nginx/domains/"${DOMAIN}"/public)
FULLURL=$(wp ${WPCLIFLAGS} option get siteurl --path=/home/nginx/domains/"${DOMAIN}"/public)

if [[ ${PERMALINKS} = '/%year%/%monthnum%/%postname%.html' ]]; then

cat <<EOT >> /usr/local/nginx/conf/wpincludes/"${DOMAIN}"/redirects.conf
# Keep these rewrite rules on the bottom of this file #
rewrite "^/[0-9]{4}/[0-9]{2}/(.*).html$" ${FULLURL}/\$1/ permanent;
rewrite "^/([0-9]{4})/([0-9]{2})/(?!page/)(.+)$" ${FULLURL}/\$3 permanent;
rewrite "^/(.+?)\.html?$" ${FULLURL}/\$1/ permanent;
# Keep these rewrite rules on the bottom of this file #
EOT

elif [[ ${PERMALINKS} = '/%year%/%monthnum%/%day%/%postname%/' ]]; then
cat <<EOT >> /usr/local/nginx/conf/wpincludes/"${DOMAIN}"/redirects.conf

# Keep these rewrite rules on the bottom of this file #
rewrite "^/([0-9]{4})/([0-9]{2})/([0-9]{2})/(?!page/)(.+)$" ${FULLURL}/\$4 permanent;
# Keep these rewrite rules on the bottom of this file #
EOT

elif [[ ${PERMALINKS} = '/%year%/%monthnum%/%postname%/' ]]; then

cat <<EOT >> /usr/local/nginx/conf/wpincludes/"${DOMAIN}"/redirects.conf
# Keep these rewrite rules on the bottom of this file #
rewrite "^/([0-9]{4})/([0-9]{2})/(?!page/)(.+)$" ${FULLURL}/\$3 permanent;
# Keep these rewrite rules on the bottom of this file #
EOT

else 
	echo "no matching permalink pattern"
	exit
fi

if ! wp ${WPCLIFLAGS} rewrite structure '/%postname%/' --path=/home/nginx/domains/"${DOMAIN}"/public >/dev/null 2>&1; then
	echo "" | mail -s "WPO URGENT - Failed to change permalinks to postname for  ${DOMAIN} -  $HOSTNAME" monitor@bigscoots.com
	exit
fi

nginx -t > /dev/null 2>&1
    if [ $? -eq 0 ]; then
                npreload > /dev/null 2>&1
        else
                "$NGINX" -t 2>&1 | mail -s "WPO URGENT - Nginx conf fail during removing permalinks -  $HOSTNAME" monitor@bigscoots.com
                exit 1
    fi

;;
*)
    echo "Must use one of the following options:
    /bigscoots/wpo/manage/permalinks.sh permalinks_curent ${DOMAIN}
    /bigscoots/wpo/manage/permalinks.sh permalinks_remove ${DOMAIN}"
    exit
    ;;
esac