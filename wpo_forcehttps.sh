#!/bin/bash

if [ -z "$1" ]

then

for i in $(find /usr/local/nginx/conf/conf.d/ -type f -printf "%f\n" |grep -v 'phpmyadmin_ssl.conf\|virtual.conf\|.ssl.conf') ; do

domain="${i//.conf/}"

cp /usr/local/nginx/conf/conf.d/"$domain".conf{,.bak}

{
echo "  server {"
echo "            listen   80;"
echo "            server_name $domain www.$domain;"
echo ""
echo "       location / {"
echo "            include /usr/local/nginx/conf/wpincludes/"$domain"/redirects.conf;"
echo "            return 301 https://$domain\$request_uri;"
echo "       }"
echo "}"


} > /usr/local/nginx/conf/conf.d/"$domain.conf"

done

else

domain="$1"

cp /usr/local/nginx/conf/conf.d/"$domain".conf{,.bak}

{
echo "  server {"
echo "            listen   80;"
echo "            server_name $domain www.$domain;"
echo ""
echo "       location / {"
echo "            include /usr/local/nginx/conf/wpincludes/"$domain"/redirects.conf;"
echo "            return 301 https://$domain\$request_uri;"
echo "       }"
echo "}"

} > /usr/local/nginx/conf/conf.d/"$domain.conf"

fi
