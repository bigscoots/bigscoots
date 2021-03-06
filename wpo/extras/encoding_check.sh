#!/bin/bash

# Check posts for possible encoding issues.

WPCLIFLAGS="--allow-root --skip-plugins --skip-themes --require=/bigscoots/includes/err_report.php"
wdpprefix=$(wp ${WPCLIFLAGS} config get table_prefix)

if [ "$(wp ${WPCLIFLAGS} db search '????' "${wdpprefix}posts" post_content | grep -A1 _posts:post_content | grep [0-9]: | sed 's/:/  /g' | awk '{print $1}' | sort | uniq  | wc -l)" -gt 0 ]; then
	echo
	echo '--------------------------------------------------------------------------------------------------------'
	echo 'This list can take a while so if you see enough just ctrl + c to stop the command it wont break anything'
	echo '--------------------------------------------------------------------------------------------------------'
	echo
	echo "Potential broken encoding issues, please check the following posts:"
	wp ${WPCLIFLAGS} db search '????' "${wdpprefix}posts" post_content --stats | grep -A1 _posts:post_content | grep "[0-9]:" | sed 's/:/  /g' | awk '{print $1}' | sort | uniq \
	| while read -r postid; do
		if wp ${WPCLIFLAGS} post list --post_status=publish --post__in="${postid}" --quiet |grep -q "${postid}"; then
			echo "$(wp ${WPCLIFLAGS} option get siteurl)/$(wp ${WPCLIFLAGS} post list --post__in="${postid}" --field=post_name)"
		fi
	done
fi