#!/bin/bash

WPCLIFLAGS="--allow-root --skip-plugins --skip-themes --require=/bigscoots/includes/err_report.php"

CF_API_EMAIL=$1
CF_API_KEY=$2
CF_API_KEY_ZONE_ID=$3

wpconfig_path=$(wp config path ${WPCLIFLAGS})

wp plugin install wp-cloudflare-page-cache --activate ${WPCLIFLAGS}

wp config set SWCFPC_CF_API_EMAIL "${CF_API_EMAIL}" ${WPCLIFLAGS}
wp config set SWCFPC_CF_API_KEY "${CF_API_KEY}" ${WPCLIFLAGS}
wp config set SWCFPC_CF_API_ZONE_ID "${CF_API_KEY_ZONE_ID}" ${WPCLIFLAGS}

