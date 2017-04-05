#!/bin/bash

yum -y update
yum -y install screen

curl -O https://centminmod.com/betainstaller.sh && chmod 0700 betainstaller.sh
screen -d -m ~/betainstaller.sh
