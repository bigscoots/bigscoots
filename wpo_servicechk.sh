#!/bin/bash

ps -ef | grep nginx: |grep -v grep > /dev/null
if [ $? != 0 ]
then
       /etc/init.d/nginx start > /dev/null
fi

ps -ef | grep crond |grep -v grep > /dev/null
if [ $? != 0 ]
then
       service crond start > /dev/null
fi

ps -ef | grep php-fpm |grep -v grep > /dev/null
if [ $? != 0 ]
then
	sleep 10
	ps -ef | grep php-fpm |grep -v grep > /dev/null
		if [ $? != 0 ]
		then	
       	fpmstart > /dev/null
    fi
fi

ps -ef | grep mysql |grep -v grep > /dev/null
if [ $? != 0 ]
then
       /etc/init.d/mysql start > /dev/null 
fi

ps -ef | grep redis |grep -v grep > /dev/null
if [ $? != 0 ]
then
   if [ -f /etc/init.d/redis ]; then
   /etc/init.d/redis start > /dev/null
     else
      systemctl start redis > /dev/null
   fi
fi

ps -ef | grep postfix |grep -v grep > /dev/null
if [ $? != 0 ]
then
   if [ -f /etc/init.d/postfix ]; then
   /etc/init.d/posfix start > /dev/null
     else
      systemctl start postfix > /dev/null
   fi
fi
