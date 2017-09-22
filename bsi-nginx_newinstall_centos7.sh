#!/bin/bash
if ping -c 1 google.com &> /dev/null
then
  crontab -r
  yum clean all
  curl -sL https://raw.githubusercontent.com/jcatello/bigscoots/master/bsi-nginx.sh | bash
  echo "nginx install for $HOSTNAME completed" | mail -s "nginx install for $HOSTNAME completed" monitor@bigscoots.com
else
  reboot
fi
