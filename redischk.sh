#!/bin/bash

if ! pgrep -x redis-server > /dev/null
then /usr/sbin/service redis start
echo down
else echo up
fi

