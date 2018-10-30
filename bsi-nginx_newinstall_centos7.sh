#!/bin/bash
if ping -c 1 google.com &> /dev/null
then
  crontab -r
  yum clean all
  curl -sL https://raw.githubusercontent.com/jcatello/bigscoots/master/bsi-nginx.sh | bash
else
  reboot
fi
