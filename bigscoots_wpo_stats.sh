#!/bin/bash

CTID=$1
dbserver=$(vzctl exec "$CTID" mysql -V)
dbversion=$(vzctl exec "$CTID" mysql -V | grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}')
nginxverison=$(vzctl exec "$CTID" nginx -v 2>&1 | awk -F '/' '{print $2}' | grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}')

if [ -e /vz/root/"$CTID"/usr/local/src/centminmod/centmin.sh ]
then
echo "$CTID is a wpo server"
vzctl exec "$CTID" php -v | head -1 | awk '{print $1, $2}'
fi

if grep -i mariadb <<< "$dbserver" > /dev/null ; then
    echo MariaDB "$dbversion"
else
	echo MySQL "$dbversion"
fi

echo Nginx "$nginxverison"
