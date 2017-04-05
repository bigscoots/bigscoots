#!/bin/bash

sleep 30
yum -y update
sleep 2
yum -y install screen
sleep 2
curl -O https://centminmod.com/betainstaller.sh
chmod 0700 betainstaller.sh
sleep 5
/usr/bin/screen -d -m ~/betainstaller.sh
