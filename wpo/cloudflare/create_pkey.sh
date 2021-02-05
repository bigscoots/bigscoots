#!/bin/bash

WPCLIFLAGS="--allow-root --skip-plugins --skip-themes --require=/bigscoots/includes/err_report.php"
DOMAIN=$1

site_id=$2
master_key=$3
p_key=$4
wpconfig_path=$(wp config path --path=/home/nginx/domains/"${DOMAIN}"/public ${WPCLIFLAGS})

mkdir -p /home/nginx/.bigscoots/cf

if [ -f /home/nginx/.bigscoots/cf/pkey_"${p_key}".php ]; then
	if ! grep -q "${site_id}" /home/nginx/.bigscoots/cf/pkey_"${p_key}".php; then
		sed -i '/SITE_ID/d' ./infile
		echo "define('SITE_ID', ${site_id});" >> /home/nginx/.bigscoots/cf/pkey_"${p_key}".php
	fi
	if ! grep -q "${master_key}" /home/nginx/.bigscoots/cf/pkey_"${p_key}".php; then
		sed -i '/MASTER_KEY/d' ./infile
		echo "define('MASTER_KEY', ${master_key});" >> /home/nginx/.bigscoots/cf/pkey_"${p_key}".php
	fi
else
	cat >/home/nginx/.bigscoots/cf/pkey_"${p_key}".php <<EOL
	define('SITE_ID', "${site_id}");
	define('MASTER_KEY', "${master_key}");
EOL
fi

if ! grep .bigscoots/cf/pkey "${wpconfig_path}"; then
	sed -ie "/if ( ! defined( 'ABSPATH' ) ) .*/i \ \n\ninclude '../../../.bigscoots/cf/pkey_${p_key}.php'; \n\n" "${wpconfig_path}"
fi