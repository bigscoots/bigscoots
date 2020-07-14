#!/bin/bash

# PHP Upgrade

/bigscoots/wpo/manage/chk_update.sh

expect /bigscoots/wpo/manage/expect/nginx

PHPVER=$(wget 'https://php.net/ChangeLog-7.php' -qO -|grep h3|sed 's/<[^<>]*>//g' | head -1 | awk '{print $2}')

if [ -z "$PHPVER" ]; then
	echo "PHP Version unable to set"
	exit
else
	sed -i "s/PHP_OVERWRITECONF='y'/PHP_OVERWRITECONF='n'/g" /usr/local/src/centminmod/centmin.sh
	expect /bigscoots/wpo/manage/expect/php "${PHPVER}"
fi