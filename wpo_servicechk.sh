#!/bin/bash

ps -ef | grep nginx |grep -v grep > /dev/null
if [ $? != 0 ]
then
       /etc/init.d/nginx start > /dev/null
fi
ps -ef | grep php5-fpm |grep -v grep > /dev/null
if [ $? != 0 ]
then
       /etc/init.d/php-fpm start > /dev/null
fi
ps -ef | grep mysql |grep -v grep > /dev/null
if [ $? != 0 ]
then
       /etc/init.d/mysql start > /dev/null 
fi
