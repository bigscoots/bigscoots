#!/bin/bash

if [[ $# -eq 0 ]]; then
    echo >&2 "Requires arguments:"
    echo >&2 "domain.com"
    echo >&2 "ALL"
    exit 1
fi

if [[ $1 = ALL ]] ; then


    while read size unit ; do fdusize=$size ; fduunit=$unit ; done <<< $(du -sh /home/nginx/domains/ | awk '{print $1}' | grep -Eo '[[:alpha:]]+|[0-9.?]+')
    while read size unit ; do ddusize=$size ; dduunit=$unit ; done <<< $(du -sh --exclude 'ib_logfile*' --exclude 'ibdata*' /var/lib/mysql/ | awk '{print $1}' | grep -Eo '[[:alpha:]]+|[0-9.?]+')
    while read size unit ; do tdusize=$size ; tduunit=$unit ; done <<< $(du -sc --exclude 'ib_logfile*' --exclude 'ibdata*' /var/lib/mysql/ /home/nginx/domains/ | tail -1 | awk '{print $1}'| awk '{ split( "K M G" , v ); s=1; while( $1>1000 ){ $1/=1000; s++ } print int($1) v[s] }' | grep -Eo '[[:alpha:]]+|[0-9.?]+')

    echo "[{\"name\": \"File Disk Usage\",\"size\": \"$fdusize\",\"value\": \"$fduunit\"},{\"name\": \"Database Disk Usage\",\"size\": \"$ddusize\",\"value\": \"$dduunit\"},{\"name\": \"Total Disk Usage\",\"size\": \"$tdusize\",\"value\": \"$tduunit\"}]"

elif [ -n "$1" ] ; then

    while read size unit ; do fdusize=$size ; fduunit=$unit ; done <<< $(du -sh /home/nginx/domains/"$1" | awk '{print $1}' | grep -Eo '[[:alpha:]]+|[0-9.?]+')
    while read size unit ; do ddusize=$size ; dduunit=$unit ; done <<< $(du -sh /var/lib/mysql/"$(grep DB_NAME /home/nginx/domains/"$1"/public/wp-config.php | grep -v WP_CACHE_KEY_SALT | grep -v '^//' | cut -d \' -f 4)" | awk '{print $1}' | grep -Eo '[[:alpha:]]+|[0-9.?]+')
    while read size unit ; do tdusize=$size ; tduunit=$unit ; done <<< $(du -sc /var/lib/mysql/"$(grep DB_NAME /home/nginx/domains/"$1"/public/wp-config.php | grep -v WP_CACHE_KEY_SALT | grep -v '^//' | cut -d \' -f 4)" /home/nginx/domains/"$1" | tail -1 | awk '{print $1}'| awk '{ split( "K M G" , v ); s=1; while( $1>1000 ){ $1/=1000; s++ } print int($1) v[s] }' | grep -Eo '[[:alpha:]]+|[0-9.?]+')

    echo "[{\"name\": \"File Disk Usage\",\"size\": \"$fdusize\",\"value\": \"$fduunit\"},{\"name\": \"Database Disk Usage\",\"size\": \"$ddusize\",\"value\": \"$dduunit\"},{\"name\": \"Total Disk Usage\",\"size\": \"$tdusize\",\"value\": \"$tduunit\"}]"

fi
