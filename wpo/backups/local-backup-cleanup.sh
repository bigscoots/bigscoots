#!/bin/bash

KEEP=125
HOWMANY=$(ls -1 /backup |grep back- | wc -l)

mkdir -p /backup/empty

if [ "$HOWMANY" -gt $KEEP ]
        then
                for i in $(ls -1 /backup | grep back- | sort -n | head -$((HOWMANY-KEEP))) ; do echo rsync -a --delete /backup/empty/ /backup/$i/ ; rsync -a --delete /backup/empty/ /backup/$i/ ; echo rm -rf /backup/$i ;  rm -rf /backup/$i  ; done
fi
