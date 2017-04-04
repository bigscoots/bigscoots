#!/bin/bash

yum -y update
screen -A -m -d -S centmininstall curl -O https://centminmod.com/betainstaller.sh && chmod 0700 betainstaller.sh && bash betainstaller.sh
