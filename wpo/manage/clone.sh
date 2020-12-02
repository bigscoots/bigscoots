#!/bin/bash

#
# Justin Catello - bigscoots.com
#

sourcesite="$1"
destinationsite="$2"
BSPATH=/root/.bigscoots

WPCLIFLAGS="--allow-root --skip-plugins --skip-themes --require=/bigscoots/includes/err_report.php"
NGINX=$(which nginx)

if [ ! -d "/home/nginx/domains/$sourcesite" ] && [ ! -d "/home/nginx/domains/$destinationsite" ]; then
    exit 2
fi

sourcesitedocroot=/home/nginx/domains/"${sourcesite}"/public
destinationsitedocroot=/home/nginx/domains/"${destinationsite}"/public

if ! sourcesitedb=$(wp ${WPCLIFLAGS} config get DB_NAME --path=${sourcesitedocroot} 2>/dev/null); then
    wp ${WPCLIFLAGS} config get DB_NAME --path=${sourcesitedocroot} 2>/dev/null
    if [ $? -eq 255 ]; then
        echo $?
        sed -i '/wp-salt.php/d' ${sourcesitedocroot}/wp-config.php
        if ! sourcesitedb=$(wp ${WPCLIFLAGS} config get DB_NAME --path=${sourcesitedocroot} 2>/dev/null); then
        echo "Something is wrong when trying to get the database name from $sourcesite site: https://github.com/jcatello/bigscoots/blob/master/wpo/manage/clone.sh#L21" | mail -s "WPO Clone failed to pull $sourcesite database name - From: $sourcesite To: $destinationsite  -  $HOSTNAME" monitor@bigscoots.com
        # exit 1
        fi
    fi
    # exit 1
fi < /dev/null 2> /dev/null

if ! destinationsitedb=$(wp ${WPCLIFLAGS} config get DB_NAME --path=${destinationsitedocroot} 2>/dev/null); then
    if [ $? -eq 255 ]; then
    sed -i '/wp-salt.php/d' ${destinationsitedocroot}/wp-config.php
        if ! destinationsitedb=$(wp ${WPCLIFLAGS} config get DB_NAME --path=${destinationsitedocroot} 2>/dev/null); then
        echo "Something is wrong when trying to get the database name from $destinationsite site: https://github.com/jcatello/bigscoots/blob/master/wpo/manage/clone.sh#L21" | mail -s "WPO Clone failed to pull $destinationsite database name - From: $sourcesite To: $destinationsite  -  $HOSTNAME" monitor@bigscoots.com
        exit 1
        fi
    fi
    exit 1
fi < /dev/null 2> /dev/null

if [[ $sourcesitedb == "$destinationsitedb" ]]; then
    if ! wp ${WPCLIFLAGS} config set DB_NAME "$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 16)" --path=${destinationsitedocroot} 2>&1; then
        exit
    fi
    if ! wp ${WPCLIFLAGS} config set DB_USER "$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 16)" --path=${destinationsitedocroot} 2>&1; then
        exit
    fi
    if ! wp ${WPCLIFLAGS} config set DB_PASSWORD "$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 16)" --path=${destinationsitedocroot} 2>&1; then
        exit
    fi
    if ! wp ${WPCLIFLAGS} db create 2>&1; then
        exit
    fi
fi < /dev/null 2> /dev/null

mkdir -p "${BSPATH}"/rsync/"${destinationsite}" "${BSPATH}"/logs
LOGFILE="clone.$(date +%Y-%m-%d_%H:%M).log"
touch "${BSPATH}"/rsync/"${destinationsite}"/exclude "${BSPATH}"/rsync/exclude
touch "${BSPATH}"/logs/"${LOGFILE}"

echo "Cloning ${sourcesite} to ${destinationsite}" > "${BSPATH}"/logs/"${LOGFILE}"
echo >> "${BSPATH}"/logs/"${LOGFILE}"
echo >> "${BSPATH}"/logs/"${LOGFILE}"

rsync -aqhv --delete --log-file="${BSPATH}"/logs/"${LOGFILE}" \
--exclude 'wp-content/uploads/backupbuddy*' \
--exclude 'wp-content/backup*' \
--exclude wp-content/uploads/backup \
--exclude wp-content/uploads/backup-guard \
--exclude wp-snapshots \
--exclude wp-content/ai1wm-backups \
--exclude wp-config.php \
--exclude debug.log \
--exclude wp-content/uploads/ShortpixelBackups \
--exclude wp-content/backup-db \
--exclude wp-content/updraft \
--exclude wp-content/cache/ \
--exclude wp-content/wpbackitup_backups \
--exclude wp-content/backupwordpress-*-backups \
--exclude wp-content/backups-dup-pro \
--exclude-from="${BSPATH}"/rsync/exclude \
--exclude-from="${BSPATH}"/rsync/"${destinationsite}"/exclude \
--exclude-from="${BSPATH}"/rsync/"${sourcesite}"/exclude \
"$sourcesitedocroot/" "$destinationsitedocroot/" >/dev/null 2>&1

rsyncVal=$?

if [ $rsyncVal -ne 0 ] && [ $rsyncVal -ne 24 ]; then
    echo "Check logfile ${BSPATH}/logs/${LOGFILE}" | mail -s "WPO Clone - Issue with rsync during clone, log path in ticket. - From: $sourcesite To: $destinationsite  -  $HOSTNAME" monitor@bigscoots.com
fi

destinationsitereplace=$(wp ${WPCLIFLAGS} option get siteurl --path="${destinationsitedocroot}" --quiet 2> /dev/null | sed -r 's/https?:\/\///g')


sourcesitedbuser=$(wp ${WPCLIFLAGS} config get DB_USER --path="${sourcesitedocroot}")
destinationsitedbuser=$(wp ${WPCLIFLAGS} config get DB_USER --path="${destinationsitedocroot}")
wdpprefix=$(wp ${WPCLIFLAGS} config get table_prefix --path="${sourcesitedocroot}")

wc_sub_url=$(mysql "${sourcesitedb}" -sNe "select option_value from ${wdpprefix}options where option_name = 'wc_subscriptions_siteurl';")

wp ${WPCLIFLAGS} db reset --yes --path="${destinationsitedocroot}" --quiet 2> /dev/null

if wp ${WPCLIFLAGS} db tables "${wdpprefix}swp_*" --format=csv --all-tables --path="${sourcesitedocroot}" >/dev/null 2>&1; then
    wp ${WPCLIFLAGS} db export - --path="${sourcesitedocroot}" --exclude_tables=$(wp ${WPCLIFLAGS} db tables "${wdpprefix}swp_*" --format=csv --all-tables --path="${sourcesitedocroot}") --quiet --single-transaction --quick --lock-tables=false --max_allowed_packet=1G --default-character-set=utf8mb4 | sed "s/DEFINER=\`${sourcesitedbuser}\`/DEFINER=\`${destinationsitedbuser}\`/g" | wp ${WPCLIFLAGS} --quiet db import - --path="${destinationsitedocroot}" --quiet --force --max_allowed_packet=1G
else
    wp ${WPCLIFLAGS} db export - --path="${sourcesitedocroot}" --quiet --single-transaction --quick --lock-tables=false --max_allowed_packet=1G --default-character-set=utf8mb4 | sed "s/DEFINER=\`${sourcesitedbuser}\`/DEFINER=\`${destinationsitedbuser}\`/g" | wp ${WPCLIFLAGS} --quiet db import - --path="${destinationsitedocroot}" --quiet --force --max_allowed_packet=1G    
fi < /dev/null 2> /dev/null

wp ${WPCLIFLAGS} config set table_prefix ${wdpprefix} --path="${destinationsitedocroot}" --quiet 2> /dev/null

if wp ${WPCLIFLAGS} config get WP_SITEURL --path="${sourcesitedocroot}" >/dev/null 2>&1; then

 wpconfigwpsiteurl=$(wp ${WPCLIFLAGS} config get WP_SITEURL --path="${sourcesitedocroot}" --quiet | sed -r 's/https?:\/\///g')
 wpdbwpsiteurl=$(wp ${WPCLIFLAGS} db query "SELECT option_value FROM "${wdpprefix}"options WHERE option_name = 'siteurl';" --skip-column-names --path="${sourcesitedocroot}" | sed -r 's/https?:\/\///g')

    if  [ ! "$wpconfigwpsiteurl" == "$wpdbwpsiteurl" ]; then
      wp ${WPCLIFLAGS} search-replace "$wpdbwpsiteurl" "$destinationsitereplace" --recurse-objects --skip-tables="${wdpprefix}"users --path="${destinationsitedocroot}" --quiet
    fi

fi < /dev/null 2> /dev/null

siteurl=$(wp ${WPCLIFLAGS} option get siteurl --path="${sourcesitedocroot}" --quiet 2> /dev/null | sed -r 's/https?:\/\///g')

wp ${WPCLIFLAGS} search-replace "$siteurl" "$destinationsitereplace" --recurse-objects --skip-tables="${wdpprefix}"users --all-tables-with-prefix="${wdpprefix}" --path="${destinationsitedocroot}" --quiet 2> /dev/null

if [ -n "$wc_sub_url" ]; then
    mysql "${destinationsitedb}" -e "update ${wdpprefix}options set option_value = '${wc_sub_url}' where ${wdpprefix}options.option_name = 'wc_subscriptions_siteurl';"
fi

if [ -n "$3" ] && [ -n "$4" ]; then

    if  ! grep -q wpolocksite /usr/local/nginx/conf/conf.d/"$2".ssl.conf ; then

        /usr/local/nginx/conf/htpasswd.sh create /home/nginx/domains/"$2"/wpolocksite "$3" "$4"
        sed -i "/location \/ {/a \  auth_basic_user_file /home/nginx/domains/$2/wpolocksite;" /usr/local/nginx/conf/conf.d/"$2".ssl.conf
        sed -i "/location \/ {/a \  auth_basic \"Private\";" /usr/local/nginx/conf/conf.d/"$2".ssl.conf

    else

        /usr/local/nginx/conf/htpasswd.sh create /home/nginx/domains/"$2"/wpolocksite "$3" "$4" >/dev/null 2>&1

    fi
fi

if [ -d "$destinationsitedocroot/wp-content/plugins/wp-rocket" ]; then

    if wp ${WPCLIFLAGS} plugin is-active wp-rocket --path="${destinationsitedocroot}"; then 
        rm -f "$destinationsitedocroot"/wp-content/advanced-cache.php
        wp plugin ${WPCLIFLAGS} deactivate wp-rocket --path="${destinationsitedocroot}" >/dev/null 2>&1
        wp plugin ${WPCLIFLAGS} activate wp-rocket --path="${destinationsitedocroot}" >/dev/null 2>&1
    fi
fi < /dev/null 2> /dev/null

if [ -f "$destinationsitedocroot"/.user.ini ]; then
    sed -i "s/$sourcesite/$destinationsite/g" "$destinationsitedocroot"/.user.ini
fi

if wp ${WPCLIFLAGS} plugin is-installed elementor --path="${destinationsitedocroot}" >/dev/null 2>&1; then
    wp ${WPCLIFLAGS} elementor flush_css --skip-plugins=$(wp ${WPCLIFLAGS} plugin list --format=csv --field=name --path="${destinationsitedocroot}" | paste -s -d, - | sed -r 's/,?elementor//g') --path="${destinationsitedocroot}" >/dev/null 2>&1
fi < /dev/null 2> /dev/null

chown -R nginx: /home/nginx/domains/$destinationsite >/dev/null 2>&1 &

# Clear All Cache

! command -v redis-cli  >/dev/null 2>&1 || redis-cli flushall  >/dev/null 2>&1
[ -d ${destinationsitedocroot}/wp-content/cache ] && rm -rf ${destinationsitedocroot}/wp-content/cache/* >/dev/null 2>&1

# Force HTTPS if not already.

if ! grep -q '# BigScoots Force HTTPS' /usr/local/nginx/conf/conf.d/"$destinationsite".conf; then
        /bigscoots/wpo_forcehttps.sh "$destinationsite"
fi

"$NGINX" -t > /dev/null 2>&1
    if [ $? -eq 0 ]; then
                npreload > /dev/null 2>&1
        else
                "$NGINX" -t 2>&1 | mail -s "WPO URGENT - Nginx conf fail during clone request - From: $sourcesite To: $destinationsite  -  $HOSTNAME" monitor@bigscoots.com
                exit 1
    fi
