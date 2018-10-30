#!/bin/bash

BKUSER=wpo$(awk '{print $1}' /proc/vz/veinfo)
BKSVR=int-backup3.bigscoots.com

if ssh -i "$HOME"/.ssh/wpo_backups "$BKUSER"@"$BKSVR" 'uptime'; [ $? -eq 255 ]
then
  echo "Connection to backup server has failed."
  exit 1
fi

echo "Available Backups:"

ssh -i "$HOME"/.ssh/wpo_backups "$BKUSER"@"$BKSVR" 'ls -1';

echo "rsync -ahv -e ssh -i $HOME/.ssh/wpo_backups --delete $BKUSER@$BKSVR:~/current/"
