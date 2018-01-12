#!/bin/bash
if ping -c 1 google.com &> /dev/null
then
  rm -rf /bigscoots
  crontab -r
  yum clean all
  curl -sL https://raw.githubusercontent.com/jcatello/bigscoots/master/bs_cpanel_initial_centos7.sh | bash
  echo "cPanel install for $HOSTNAME completed" | mail -s "cPanel install for $HOSTNAME completed" monitor@bigscoots.com
else
  reboot
fi
