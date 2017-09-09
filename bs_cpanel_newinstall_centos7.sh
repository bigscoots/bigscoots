#!/bin/bash
if ping -c 1 google.com &> /dev/null
then
  crontab -r
  yum clean all
  curl -sL https://raw.githubusercontent.com/jcatello/bigscoots/master/bs_cpanel_initial_centos7.sh?1 | bash
  echo "cPanel install for $HOSTNAME completed" | mail -s "cPanel install for $HOSTNAME completed" monitor@bigscoots.com
else
  reboot
fi
