#!/bin/bash

# Check posts for possible encoding issues.

echo 'This list can take a while so if you see enough just ctrl + c to stop the command it wont break anything'

if [ "$(wp db search '????' wp_posts post_content | grep -A1 _posts:post_content | grep [0-9]: | sed 's/:/  /g' | awk '{print $1}' | sort | uniq  | wc -l)" -gt 0 ]; then
	echo "Potential broken encoding issues, please check the following posts:"
	wp db search '????' wp_posts post_content --stats | grep -A1 _posts:post_content | grep "[0-9]:" | sed 's/:/  /g' | awk '{print $1}' | sort | uniq \
	| while read -r postid; do
		if wp post list --post_status=publish --post__in="${postid}" --quiet |grep -q "${postid}"; then
			echo "$(wp option get siteurl)/$(wp post list --post__in="${postid}" --field=post_name)"
		fi
	done
fi