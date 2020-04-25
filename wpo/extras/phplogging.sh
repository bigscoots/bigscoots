#!/bin/bash

# Gives us PHP logging per vhost even though one pool

# disable global error log which prevents .user.ini from working

if grep -o '^php_admin_value\[error_log\]' /usr/local/etc/php-fpm.conf >/dev/null 2>&1; then
 sed -i 's/php_admin_value\[error_log\]/;php_admin_value\[error_log\]/g' /usr/local/etc/php-fpm.conf
fi

for WPATH in $(find /home/nginx/domains/*/public -maxdepth 1 -type d -name public); do

	PHPLOGFILE=$(echo "$WPATH" | sed 's/\/public/\/log\/php_error.log/g')

	if [ ! -f "${WPATH}"/.user.ini ]; then
		touch "${WPATH}"/.user.ini
	fi

	if grep -q "^error_log" "${WPATH}"/.user.ini >/dev/null 2>&1; then
	 	sed -i "/^error_log/c\error_log = ${PHPLOGFILE}" "${WPATH}"/.user.ini
 	else
 		echo "error_log = ${PHPLOGFILE}" >> "${WPATH}"/.user.ini
 	fi

done