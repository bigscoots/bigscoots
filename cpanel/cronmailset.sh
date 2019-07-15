#!/bin/bash

for i in $(whmapi1 list_users |grep - | awk '{print $2}' | awk /./) ; do 
if [[ $(crontab -u $i -l | egrep -v "^(#|$)" | grep -q 'MAILTO='; echo $?) == 1 ]]
then
    crontab -u $i -l | { echo MAILTO=\"\"; cat;  } | crontab -u $i -
fi
done
