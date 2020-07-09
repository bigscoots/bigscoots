#!/bin/bash

domain="$2"
WPCLIFLAGS="--allow-root --skip-plugins --skip-themes --require=/bigscoots/includes/err_report.php"


case $1 in
list_plugins)

# /bigscoots/wpo/manage/plugins.sh list_plugins ${DOMAIN}

wp --allow-root --skip-themes plugin list --fields=name,title,status,update,version,update_version --format=json --path=/home/nginx/domains/"$domain"/public

;;
update_plugin)

# /bigscoots/wpo/manage/plugins.sh update_plugin ${DOMAIN} ${PLUGIN}

plugin="$3"

wp --allow-root --skip-themes plugin update "$plugin" --path=/home/nginx/domains/"$domain"/public

;;
toggle_plugin)

# /bigscoots/wpo/manage/plugins.sh toggle_plugin ${DOMAIN} ${PLUGIN}

plugin="$3"

wp ${WPCLIFLAGS} plugin toggle "$plugin" --path=/home/nginx/domains/"$domain"/public

;;
uninstall_plugin)

# /bigscoots/wpo/manage/plugins.sh uninstall_plugin ${DOMAIN} ${PLUGIN}

plugin="$3"

wp ${WPCLIFLAGS} plugin uninstall "$plugin" --deactivate --path=/home/nginx/domains/"$domain"/public 2>/dev/null || exit 0

;;
esac