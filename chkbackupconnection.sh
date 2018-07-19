#!/bin/bash

BKUSER=wpo$(awk '{print $1}' /proc/vz/veinfo)
BKSVR=backup3.bigscoots.com

if ssh -i "$HOME"/.ssh/wpo_backups "$BKUSER"@"$BKSVR" 'uptime'; [ $? -eq 255 ]
then
  echo "Mark for Justin" | mail -s "$HOSTNAME- WPO failed to SSH to backup server." monitor@bigscoots.com
  exit 1
fi
