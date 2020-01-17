#!/bin/bash

# Staging


BSPATH=/root/.bigscoots
sourcedomain="$1"
destinationdomain="$2"

mkdir -p "${BSPATH}"/rsync/"${destinationdomain}"
touch "${BSPATH}"/rsync/"${destinationdomain}"/exclude "${BSPATH}"/rsync/exclude

sourcedomainsize="$(du --exclude-from="${BSPATH}"/rsync/"${destinationdomain}"/exclude --exclude updraft --exclude ai1wm-backups --exclude cache -s /home/nginx/domains/"$sourcedomain" | awk '{print $1}')"
freespace="$(df -k / | tr -s ' ' | cut -d" " -f 4 | grep -v Available)"
percentofreespace=$((sourcedomainsize*100/freespace))

if [ ! -d /home/nginx/domains/"$destinationdomain" ] && [ "$percentofreespace" -ge 45 ] ; then
        echo "$sourcedomain is using  $percentofreespace% of the available free space, we require less than 40% to prevent server from running out of space." | mail -s "WPO Staging attemped but not enough disk space on  $HOSTNAME" monitor@bigscoots.com
        exit 1
fi

if [ ! -d /home/nginx/domains/"$destinationdomain" ] ; then
        echo "$destinationdomain doesn't exist, creating it..."
        /bigscoots/wpo/manage/createdomain.sh "$destinationdomain"
fi

/bigscoots/wpo/manage/clone.sh "$sourcedomain" "$destinationdomain" dev dev

if grep -q 'return 301 https' /usr/local/nginx/conf/conf.d/"$sourcedomain".conf && ! grep -q 'BigScoots Force HTTPS' /usr/local/nginx/conf/conf.d/"$destinationdomain".conf; then
        echo "https redirect found, redirecting staging."
        /bigscoots/wpo_forcehttps.sh "$destinationdomain"
    nginx -t > /dev/null 2>&1
    if [ $? -eq 0 ]; then
                sleep 15
                npreload > /dev/null 2>&1
        else
                nginx -t 2>&1 | mail -s "WPO URGENT - Nginx conf fail during staging request -  $HOSTNAME" monitor@bigscoots.com
                exit 1
    fi
fi

echo "" | mail -s "WPO Staging completed on  $HOSTNAME for  $destinationdomain add DNS" monitor@bigscoots.com