#!/bin/bash

# Gives us PHP logging per vhost even though one pool

# disable global error log which prevents .user.ini from working

if grep -o '^php_admin_value\[error_log\]' /usr/local/etc/php-fpm.conf >/dev/null 2>&1; then
 sed -i 's/php_admin_value\[error_log\]/;php_admin_value\[error_log\]/g' /usr/local/etc/php-fpm.conf
fi

# find all available paths to place the .user.ini

for WPATH in $(find /home/nginx/domains/*/public -maxdepth 1 -type d -name public); do

	# Set the full path including filename of the PHP error_log.

	PHPLOGFILE=$(echo "$WPATH" | sed 's/\/public/\/log\/php_error.log/g')

	# if the .user.ini doesn't exist it will create it, if it fails to create, it will send you an email.

	if [ ! -f "${WPATH}"/.user.ini ]; then
		if ! touch "${WPATH}"/.user.ini; then
			echo "" | mail -s "Failed to create ${WPATH}/.user.ini on  $HOSTNAME - leave for justin" monitor@bigscoots.com
		fi
	fi

	# will replace error_log option that specifies the location of the log file if it already exists but does not match the correct path and then reloads php-fpm

	if grep -q "^error_log" "${WPATH}"/.user.ini && ! grep -q "error_log = ${PHPLOGFILE}" "${WPATH}"/.user.ini >/dev/null 2>&1; then
	 	sed -i "/^error_log/c\error_log = ${PHPLOGFILE}" "${WPATH}"/.user.ini
	 	fpmreload
 	else

 	# adds the error_log option if it doesn't exist and reloads php-fpm
 		echo "error_log = ${PHPLOGFILE}" >> "${WPATH}"/.user.ini
 		fpmreload
 	fi

 	# fix ownership of the .user.ini
 	chown nginx: "${WPATH}"/.user.ini

done