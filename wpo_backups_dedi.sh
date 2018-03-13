#!/bin/bash

date=$(date "+%Y-%m-%dT%H_%M_%S")
HOME=/home/nginx/domains/

rsync -azP \
  --delete \
  --delete-excluded \
  --exclude-from="$HOME".rsync/exclude \
  --link-dest=../current \
  "$HOME" /backup/incomplete_back-"$date" \
  mv /backup/incomplete_back-"$date" back-"$date" \
  && rm -f /backup/current \
  && ln -s /backup/back-"$date" /backup/current
