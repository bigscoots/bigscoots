#!/bin/bash

# PHP Upgrade

echo 
echo 
echo "Running updates..."

/bigscoots/wpo/manage/chk_update.sh

echo 
echo 
echo "Upgrading nginx..."

expect /bigscoots/wpo/manage/expect/nginx

echo 
echo 
echo "Upgrading php..."

if [ -z "$1" ]; then
	PHPVER=$(wget 'https://php.net/ChangeLog-7.php' -qO -|grep h3|sed 's/<[^<>]*>//g' | head -1 | awk '{print $2}')
else
	PHPVER="$1"
fi

if [ -z "$PHPVER" ]; then
	echo "PHP Version unable to set"
	exit
else
	sed -i "s/PHP_OVERWRITECONF='y'/PHP_OVERWRITECONF='n'/g" /usr/local/src/centminmod/centmin.sh
	sed -i "s/PHPFINFO='n'/PHPFINFO='y'/g" /usr/local/src/centminmod/centmin.sh
	expect /bigscoots/wpo/manage/expect/php "${PHPVER}"
fi

echo 
echo 
echo "Finished!"

nginx -v

echo
echo

php -v