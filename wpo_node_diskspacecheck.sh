#!/bin/bash

RE='^[0-9]+$'

if [[ $# -eq 0 ]]; then
    echo >&2 "Requires arguments:"
    echo >&2 "CTID"
    echo >&2 "ALL"
    exit 1
fi

if [[ $1 = ALL ]] ; then

        vzlist \
        | grep -v HOSTNAME \
        | grep wpo \
        | awk '{print $1, $5}' \
        |  while read -r id hostname

          do

          CTID="$id"
          VZHOSTNAME="$hostname"
          FDU=$(du -sh /vz/root/"$CTID"/home/nginx/domains/ | awk '{print $1}')
          DDU=$(du -sh --exclude 'ib_logfile*' --exclude 'ibdata*' /vz/root/"$CTID"/var/lib/mysql/ | awk '{print $1}')
          TDU=$(du -sc --exclude 'ib_logfile*' --exclude 'ibdata*' /vz/root/"$CTID"/var/lib/mysql/ /vz/root/"$CTID"/home/nginx/domains/ | tail -1 | awk '{print $1}' | awk '{ byte =$1 /1024/1024; print byte " GB" }')

          echo "File Disk Usage: $FDU"
          echo "Database Disk Usage: $DDU"
          echo "Total Disk Usage: $TDU"

  if ((${TDU%.*} > 10 )) ; then
        du -sh /vz/root/"$CTID"/home/nginx/domains/*/public/*/*/*/* \
        | sort -h \
        | tail -10 \
        | sed "s=/vz/root/$CTID/home/nginx/domains/==g" \
        | mail -s "WPO over 10GB - $VZHOSTNAME - $TDU " monitor@bigscoots.com
  fi

          done

elif [[ $1 =~ $RE ]] ; then

CTID=$1
VZHOSTNAME=$(vzlist | grep "$CTID" | awk '{print $5}')
FDU=$(du -sh /vz/root/"$CTID"/home/nginx/domains/ | awk '{print $1}')
DDU=$(du -sh --exclude 'ib_logfile*' --exclude 'ibdata*' /vz/root/"$CTID"/var/lib/mysql/ | awk '{print $1}')
TDU=$(du -sc --exclude 'ib_logfile*' --exclude 'ibdata*' /vz/root/"$CTID"/var/lib/mysql/ /vz/root/"$CTID"/home/nginx/domains/ | tail -1 | awk '{print $1}' | awk '{ byte =$1 /1024/1024; print byte " GB" }')

echo "File Disk Usage: $FDU"
echo "Database Disk Usage: $DDU"
echo "Total Disk Usage: $TDU"

  if ((${TDU%.*} > 10 )) ; then
        du -sh /vz/root/"$CTID"/home/nginx/domains/*/public/*/*/*/* \
        | sort -h \
        | tail -10 \
        | sed "s=/vz/root/$CTID/home/nginx/domains/==g" \
        | mail -s "WPO over 10GB - $VZHOSTNAME - $TDU " monitor@bigscoots.com
fi
else

    echo >&2 "Requires arguments:"
    echo >&2 "CTID"
    echo >&2 "ALL"
    exit 1

  fi
