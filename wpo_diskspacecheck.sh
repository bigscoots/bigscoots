#!/bin/bash

if [[ $# -eq 0 ]]; then
    echo >&2 "Requires arguments:"
    echo >&2 "domain.com"
    echo >&2 "ALL"
    exit 1
fi

if [[ $1 = ALL ]] ; then

          FDU=$(du -sh /home/nginx/domains/ | awk '{print $1}')
          DDU=$(du -sh --exclude 'ib_logfile*' --exclude 'ibdata*' /var/lib/mysql/ | awk '{print $1}')
          TDU=$(du -sc --exclude 'ib_logfile*' --exclude 'ibdata*' /var/lib/mysql/ /home/nginx/domains/ | tail -1 | awk '{print $1}'| awk '{ split( "KB MB GB" , v ); s=1; while( $1>1024 ){ $1/=1024; s++ } print int($1) v[s] }')
          echo "File Disk Usage: $FDU"
          echo "Database Disk Usage: $DDU"
          echo "Total Disk Usage: $TDU"

elif [ -n "$1" ] ; then

         FDU="$(du -sh /home/nginx/domains/"$1" | awk '{print $1}')"
         DDU="$(du -sh /var/lib/mysql/"$(grep DB_NAME /home/nginx/domains/"$1"/public/wp-config.php | grep -v WP_CACHE_KEY_SALT | grep -v '^//' | cut -d \' -f 4)" | awk '{print $1}')"
         TDU="$(du -sc /var/lib/mysql/"$(grep DB_NAME /home/nginx/domains/"$1"/public/wp-config.php | grep -v WP_CACHE_KEY_SALT | grep -v '^//' | cut -d \' -f 4)" /home/nginx/domains/"$1" | tail -1 | awk '{print $1}'| awk '{ split( "KB MB GB" , v ); s=1; while( $1>1024 ){ $1/=1024; s++ } print int($1) v[s] }')"
         echo "File Disk Usage: $FDU"
         echo "Database Disk Usage: $DDU"
         echo "Total Disk Usage: $TDU"
fi
