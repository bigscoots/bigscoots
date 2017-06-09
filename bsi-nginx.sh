#!/bin/bash

sleep 30
yum clean all
yum -y update
sleep 2
yum -y install screen
sleep 2
cd /home
curl -o betainstaller.sh -L https://centminmod.com/betainstaller.sh
sleep 5
/usr/bin/screen -d -m sh betainstaller.sh
export EDITOR=nano
