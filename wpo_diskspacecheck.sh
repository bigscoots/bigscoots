#!/bin/bash

if [[ $# -eq 0 ]]; then
    echo >&2 "Requires arguments:"
    echo >&2 "domain.com"
    echo >&2 "ALL"
    exit 1
fi

if [[ $1 = ALL ]] ; then


    while read size unit ; do fdusize=$size ; fduunit=$unit ; done <<< $(du -sh /home/nginx/domains/ | tail -1 | awk '{print $1}' | sed -r 's/([0-9])([a-zA-Z])/\1 \2/g')
    while read size unit ; do ddusize=$size ; dduunit=$unit ; done <<< $(du -sh --exclude 'ib_logfile*' --exclude 'ibdata*' /var/lib/mysql/ | tail -1 | awk '{print $1}' | sed -r 's/([0-9])([a-zA-Z])/\1 \2/g')
    while read size unit ; do tdusize=$size ; tduunit=$unit ; done <<< $(du -sh --exclude 'ib_logfile*' --exclude 'ibdata*' /var/lib/mysql/ /home/nginx/domains/ | tail -1 | awk '{print $1}' | sed -r 's/([0-9])([a-zA-Z])/\1 \2/g')

    echo "[{\"name\": \"File Disk Usage\",\"size\": \"$fdusize\",\"value\": \"$fduunit\"},{\"name\": \"Database Disk Usage\",\"size\": \"$ddusize\",\"value\": \"$dduunit\"},{\"name\": \"Total Disk Usage\",\"size\": \"$tdusize\",\"value\": \"$tduunit\"}]"

elif [ -n "$1" ] ; then

    while read size unit ; do fdusize=$size ; fduunit=$unit ; done <<< $(du -sh /home/nginx/domains/"$1" | awk '{print $1}' | sed -r 's/([0-9])([a-zA-Z])/\1 \2/g')
    while read size unit ; do ddusize=$size ; dduunit=$unit ; done <<< $(du -sh /var/lib/mysql/"$(grep DB_NAME /home/nginx/domains/"$1"/public/wp-config.php | grep -v WP_CACHE_KEY_SALT | grep -v '^//' | cut -d \' -f 4)" | awk '{print $1}' | sed -r 's/([0-9])([a-zA-Z])/\1 \2/g')
    while read size unit ; do tdusize=$size ; tduunit=$unit ; done <<< $(du -sh /var/lib/mysql/"$(grep DB_NAME /home/nginx/domains/"$1"/public/wp-config.php | grep -v WP_CACHE_KEY_SALT | grep -v '^//' | cut -d \' -f 4)" /home/nginx/domains/"$1" | tail -1 | awk '{print $1}'| sed -r 's/([0-9])([a-zA-Z])/\1 \2/g')

    echo "[{\"name\": \"File Disk Usage\",\"size\": \"$fdusize\",\"value\": \"$fduunit\"},{\"name\": \"Database Disk Usage\",\"size\": \"$ddusize\",\"value\": \"$dduunit\"},{\"name\": \"Total Disk Usage\",\"size\": \"$tdusize\",\"value\": \"$tduunit\"}]"

fi
