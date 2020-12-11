#!/bin/bash

if [ -f /usr/local/apache/conf/includes/pre_main_global.conf ] && ! grep -qi SymlinkProtect /usr/local/apache/conf/httpd.conf; then
	cat <<EOT >> /usr/local/apache/conf/includes/pre_main_global.conf
SymlinkProtect On
SymlinkProtectRoot /var/www/html
EOT
fi

if ! apachectl -k restart; then 
	exit 1
fi