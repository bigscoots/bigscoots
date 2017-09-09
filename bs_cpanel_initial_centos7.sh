#!/bin/bash

yum clean all

if [[ ! -f /usr/bin/git || ! -f /usr/bin/curl || ! -f /usr/bin/nano ]]; then
  echo
  echo "installing yum packages..."
  echo
  yum -y install git nano wget curl
fi
  if [ -f /etc/selinux/config ]; then
  sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config && setenforce 0
  sed -i 's/SELINUX=permissive/SELINUX=disabled/g' /etc/selinux/config && setenforce 0
fi

cd /
git clone https://github.com/jcatello/bigscoots
/bigscoots/bs_cpanel_install_centos7.sh
