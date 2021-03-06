#!/bin/bash

# Staging


BSPATH=/root/.bigscoots
sourcedomain="$1"
destinationdomain="$2"
skip=0
fresh=0

WPCLIFLAGS="--allow-root --skip-plugins --skip-themes --require=/bigscoots/includes/err_report.php"

if [ "$3" == skip ]; then 
    skip=1
fi

if [ "$3" == fresh ]; then 
    fresh=1
    skip=1
fi

mkdir -p "${BSPATH}"/rsync/"${destinationdomain}"
touch "${BSPATH}"/rsync/"${destinationdomain}"/exclude "${BSPATH}"/rsync/exclude

if [ "$skip" == 0 ]; then

    sourcedomainsize="$(du \
    --exclude-from="${BSPATH}"/rsync/exclude \
    --exclude-from="${BSPATH}"/rsync/"${destinationdomain}"/exclude \
    --exclude 'wp-content/uploads/backupbuddy*' \
    --exclude 'wp-content/backup*' \
    --exclude wp-content/uploads/backup \
    --exclude wp-content/uploads/backup-guard \
    --exclude wp-snapshots \
    --exclude wp-content/ai1wm-backups \
    --exclude wp-content/uploads/ShortpixelBackups \
    --exclude wp-content/backup-db \
    --exclude wp-content/updraft \
    --exclude wp-content/cache \
    --exclude wp-content/wpbackitup_backups \
    --exclude wp-content/backupwordpress-*-backups \
    --exclude wp-content/backups-dup-pro \
    -s /home/nginx/domains/"$sourcedomain" | awk '{print $1}')"
    freespace="$(df -k / | tr -s ' ' | cut -d" " -f 4 | grep -v Available)"
    percentofreespace=$((sourcedomainsize*100/freespace))

    if [ ! -d /home/nginx/domains/"$destinationdomain" ] && [ "$percentofreespace" -ge 45 ] ; then
        echo "$sourcedomain is using  $percentofreespace% of the available free space, we require less than 40% to prevent server from running out of space." | mail -s "WPO Staging attemped but not enough disk space on  $HOSTNAME" monitor@bigscoots.com
        echo "space is unavailable"
        exit 1
    fi

fi

if [ ! -d /home/nginx/domains/"$destinationdomain" ] ; then
    if [ "$3" == fresh ]; then  
        /bigscoots/wpo/manage/createdomain.sh "$destinationdomain" fresh skipcache
    else   
        /bigscoots/wpo/manage/createdomain.sh "$destinationdomain"
    fi
fi

if [ "$fresh" == 0 ]; then
    /bigscoots/wpo/manage/clone.sh "$sourcedomain" "$destinationdomain" dev dev
fi

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

wp ${WPCLIFLAGS} config set JETPACK_STAGING_MODE true --raw --path=/home/nginx/domains/"$destinationdomain"/public/ > /dev/null 2>&1

if [ ! -f /root/.bigscoots/staging/"$destinationdomain"/enable_mail ]; then 
    if ! grep -q "function wp_mail()" /home/nginx/domains/"$destinationdomain"/public/wp-config.php > /dev/null 2>&1 ; then

cat <<EOT >> /home/nginx/domains/"$destinationdomain"/public/wp-config.php



// Disable Outgoing WordPress Emails Should exist in Staging only
function wp_mail() {
    //
}
EOT
    fi
fi