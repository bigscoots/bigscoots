#!/bin/bash

date=$(date "+%Y-%m-%dT%H_%M_%S")
HOME=/home/nginx/domains/
BKUSER=wpo$(awk '{print $1}' /proc/vz/veinfo)
BKSVR=int-backup3.bigscoots.com

rsync -azP \
  --delete \
  --delete-excluded \
  --exclude-from="$HOME".rsync/exclude \
  --link-dest=../current \
  "$HOME" "$BKUSER"@"$BKSVR":incomplete_back-"$date" \
  && ssh -i ~/.ssh/wpo_backups "$BKUSER"@"$BKSVR" \
  "mv incomplete_back-$date back-$date \
  && rm -f current \
  && ln -s back-$date current"
