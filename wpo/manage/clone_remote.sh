#!/bin/bash

#
# Justin Catello - bigscoots.com
#

SOURCESITE="$1"
DESTINATIONSITE="$2"
BSPATH=/root/.bigscoots
REMOTEHOST=69.162.173.120
REMOTEPORT=2222

WPCLIFLAGS="--allow-root --skip-plugins --skip-themes --require=/bigscoots/includes/err_report.php"
NGINX=$(which nginx)

SOURCESITEDOCROOT=/home/nginx/domains/"${SOURCESITE}"/public
DESTINATIONSITEDOCROOT=/home/nginx/domains/"${DESTINATIONSITE}"/public

if wp ${WPCLIFLAGS} core is-installed --path="${SOURCESITEDOCROOT}" --ssh="${REMOTEHOST}":"${REMOTEPORT}" --ssh="${REMOTEHOST}":"${REMOTEPORT}" && wp ${WPCLIFLAGS} core is-installed --path="${DESTINATIONSITEDOCROOT}" ; then
	echo "${SOURCESITE} or ${DESTINATIONSITE} does not exist."
    exit
fi

if ! SOURCESITEDB=$(wp ${WPCLIFLAGS} config get DB_NAME --path=${SOURCESITEDOCROOT} --ssh="${REMOTEHOST}":"${REMOTEPORT}" > /dev/null 2>&1); then
    wp ${WPCLIFLAGS} config get DB_NAME --path=${SOURCESITEDOCROOT} --ssh="${REMOTEHOST}":"${REMOTEPORT}" > /dev/null 2>&1
    if [ $? -eq 255 ]; then
        echo $?
        sed -i '/wp-salt.php/d' ${SOURCESITEDOCROOT}/wp-config.php
        if ! SOURCESITEDB=$(wp ${WPCLIFLAGS} config get DB_NAME --path=${SOURCESITEDOCROOT} --ssh="${REMOTEHOST}":"${REMOTEPORT}" 2>&1); then
        echo "Something is wrong when trying to get the database name from $SOURCESITE site: https://github.com/jcatello/bigscoots/blob/master/wpo/manage/clone.sh#L21" | mail -s "WPO Clone failed to pull $SOURCESITE database name - From: $SOURCESITE To: $DESTINATIONSITE  -  $HOSTNAME" monitor@bigscoots.com
        # exit 1
        fi
    fi
    # exit 1
fi

if ! DESTINATIONSITEDB=$(wp ${WPCLIFLAGS} config get DB_NAME --path=${DESTINATIONSITEDOCROOT} 2>&1); then
    if [ $? -eq 255 ]; then
    sed -i '/wp-salt.php/d' ${DESTINATIONSITEDOCROOT}/wp-config.php
        if ! DESTINATIONSITEDB=$(wp ${WPCLIFLAGS} config get DB_NAME --path=${DESTINATIONSITEDOCROOT} 2>&1); then
        echo "Something is wrong when trying to get the database name from $DESTINATIONSITE site: https://github.com/jcatello/bigscoots/blob/master/wpo/manage/clone.sh#L21" | mail -s "WPO Clone failed to pull $DESTINATIONSITE database name - From: $SOURCESITE To: $DESTINATIONSITE  -  $HOSTNAME" monitor@bigscoots.com
        exit 1
        fi
    fi
    exit 1
fi

if [[ $SOURCESITEDB == $DESTINATIONSITEDB ]]; then
    if ! wp ${WPCLIFLAGS} config set DB_NAME "$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 16)" --path=${DESTINATIONSITEDOCROOT} 2>&1; then
        exit
    fi
    if ! wp ${WPCLIFLAGS} config set DB_USER "$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 16)" --path=${DESTINATIONSITEDOCROOT} 2>&1; then
        exit
    fi
    if ! wp ${WPCLIFLAGS} config set DB_PASSWORD "$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 16)" --path=${DESTINATIONSITEDOCROOT} 2>&1; then
        exit
    fi
    if ! wp ${WPCLIFLAGS} db create 2>&1; then
        exit
    fi
fi

mkdir -p "${BSPATH}"/rsync/"${DESTINATIONSITE}"
touch "${BSPATH}"/rsync/"${DESTINATIONSITE}"/exclude "${BSPATH}"/rsync/exclude

rsync -aqhv -e "ssh -p ${REMOTEPORT}" \
--delete \
--exclude 'wp-content/uploads/backupbuddy*' \
--exclude 'wp-content/backup*' \
--exclude wp-content/uploads/backup \
--exclude wp-content/uploads/backup-guard \
--exclude wp-snapshots \
--exclude wp-content/ai1wm-backups \
--exclude wp-config.php \
--exclude wp-content/uploads/ShortpixelBackups \
--exclude wp-content/backup-db \
--exclude wp-content/updraft \
--exclude wp-content/cache/ \
--exclude wp-content/wpbackitup_backups \
--exclude-from="${BSPATH}"/rsync/exclude \
--exclude-from="${BSPATH}"/rsync/"${DESTINATIONSITE}"/exclude \
"${REMOTEHOST}":"${SOURCESITEDOCROOT}/" "${DESTINATIONSITEDOCROOT}/"

DESTINATIONSITEREPLACE=$(wp ${WPCLIFLAGS} option get siteurl --path="${DESTINATIONSITEDOCROOT}" --quiet | sed -r 's/https?:\/\///g')


SOURCESITEDBUSER=$(wp ${WPCLIFLAGS} config get DB_USER --path="${SOURCESITEDOCROOT}" --ssh="${REMOTEHOST}":"${REMOTEPORT}")
DESTINATIONSITEDBUSER=$(wp ${WPCLIFLAGS} config get DB_USER --path="${DESTINATIONSITEDOCROOT}")
WDPPREFIX=$(wp ${WPCLIFLAGS} config get table_prefix --path="${SOURCESITEDOCROOT}" --ssh="${REMOTEHOST}":"${REMOTEPORT}")

wp ${WPCLIFLAGS} db reset --yes --path="${DESTINATIONSITEDOCROOT}" --quiet

if wp ${WPCLIFLAGS} db tables "${WDPPREFIX}swp_*" --format=csv --all-tables --path="${SOURCESITEDOCROOT}" --ssh="${REMOTEHOST}":"${REMOTEPORT}" >/dev/null 2>&1; then
    wp ${WPCLIFLAGS} db export - --path="${SOURCESITEDOCROOT}" --ssh="${REMOTEHOST}":"${REMOTEPORT}" --exclude_tables=$(wp ${WPCLIFLAGS} db tables "${WDPPREFIX}swp_*" --format=csv --all-tables --path="${SOURCESITEDOCROOT}" --ssh="${REMOTEHOST}":"${REMOTEPORT}") --quiet --single-transaction --quick --lock-tables=false --max_allowed_packet=1G | sed "s/DEFINER=\`${SOURCESITEDBUSER}\`/DEFINER=\`${DESTINATIONSITEDBUSER}\`/g" | wp ${WPCLIFLAGS} --quiet db import - --path="${DESTINATIONSITEDOCROOT}" --quiet --force --max_allowed_packet=1G
else
    wp ${WPCLIFLAGS} db export - --path="${SOURCESITEDOCROOT}" --ssh="${REMOTEHOST}":"${REMOTEPORT}" --quiet --single-transaction --quick --lock-tables=false --max_allowed_packet=1G | sed "s/DEFINER=\`${SOURCESITEDBUSER}\`/DEFINER=\`${DESTINATIONSITEDBUSER}\`/g" | wp ${WPCLIFLAGS} --quiet db import - --path="${DESTINATIONSITEDOCROOT}" --quiet --force --max_allowed_packet=1G    
fi

wp ${WPCLIFLAGS} config set table_prefix ${WDPPREFIX} --path="${DESTINATIONSITEDOCROOT}" --quiet

if wp ${WPCLIFLAGS} config get WP_SITEURL --path="${SOURCESITEDOCROOT}" --ssh="${REMOTEHOST}":"${REMOTEPORT}" >/dev/null 2>&1; then

 WPCONFIGWPSITEURL=$(wp ${WPCLIFLAGS} config get WP_SITEURL --path="${SOURCESITEDOCROOT}" --ssh="${REMOTEHOST}":"${REMOTEPORT}" --quiet | sed -r 's/https?:\/\///g')
 WPDBWPSITEURL=$(wp ${WPCLIFLAGS} db query "SELECT option_value FROM "${WDPPREFIX}"options WHERE option_name = 'siteurl';" --skip-column-names --path="${SOURCESITEDOCROOT}" --ssh="${REMOTEHOST}":"${REMOTEPORT}" | sed -r 's/https?:\/\///g')

    if  [ ! "$WPCONFIGWPSITEURL" == "$WPDBWPSITEURL" ]; then
      wp ${WPCLIFLAGS} search-replace "$WPDBWPSITEURL" "$DESTINATIONSITEREPLACE" --recurse-objects --skip-columns=guid --skip-tables="${WDPPREFIX}"users --path="${DESTINATIONSITEDOCROOT}" --quiet
    fi

fi

SITEURLSOURCE=$(wp ${WPCLIFLAGS} option get siteurl --path="${SOURCESITEDOCROOT}" --ssh="${REMOTEHOST}":"${REMOTEPORT}" --quiet | sed -r 's/https?:\/\///g')

wp ${WPCLIFLAGS} search-replace "$SITEURLSOURCE" "$DESTINATIONSITEREPLACE" --recurse-objects --skip-columns=guid --skip-tables="${WDPPREFIX}"users --path="${DESTINATIONSITEDOCROOT}" --quiet

if [ -n "$3" ] && [ -n "$4" ]; then

    if  ! grep -q wpolocksite /usr/local/nginx/conf/conf.d/"$2".ssl.conf ; then

        /usr/local/nginx/conf/htpasswd.sh create /home/nginx/domains/"$2"/wpolocksite "$3" "$4"
        sed -i "/location \/ {/a \  auth_basic_user_file /home/nginx/domains/$2/wpolocksite;" /usr/local/nginx/conf/conf.d/"$2".ssl.conf
        sed -i "/location \/ {/a \  auth_basic \"Private\";" /usr/local/nginx/conf/conf.d/"$2".ssl.conf

    else

        /usr/local/nginx/conf/htpasswd.sh create /home/nginx/domains/"$2"/wpolocksite "$3" "$4" >/dev/null 2>&1

    fi
fi

if [ -d "$DESTINATIONSITEDOCROOT/wp-content/plugins/wp-rocket" ]; then

    if wp ${WPCLIFLAGS} plugin is-active wp-rocket --path="${DESTINATIONSITEDOCROOT}"; then 
        rm -f "$DESTINATIONSITEDOCROOT"/wp-content/advanced-cache.php
        wp plugin ${WPCLIFLAGS} deactivate wp-rocket --path="${DESTINATIONSITEDOCROOT}"
        wp plugin ${WPCLIFLAGS} activate wp-rocket --path="${DESTINATIONSITEDOCROOT}"
    fi
fi

if [ -f "$DESTINATIONSITEDOCROOT"/.user.ini ]; then
    sed -i "s/$SOURCESITE/$DESTINATIONSITE/g" "$DESTINATIONSITEDOCROOT"/.user.ini
fi

if wp ${WPCLIFLAGS} plugin is-installed elementor --path="${DESTINATIONSITEDOCROOT}" >/dev/null 2>&1; then
    wp ${WPCLIFLAGS} elementor flush_css --skip-plugins=$(wp ${WPCLIFLAGS} plugin list --format=csv --field=name --path="${DESTINATIONSITEDOCROOT}" | paste -s -d, - | sed -r 's/,?elementor//g') --path="${DESTINATIONSITEDOCROOT}"
fi

chown -R nginx: /home/nginx/domains/$DESTINATIONSITE &

# Clear All Cache

! command -v redis-cli  >/dev/null 2>&1 || redis-cli flushall  >/dev/null 2>&1
[ -d ${DESTINATIONSITEDOCROOT}/wp-content/cache ] && rm -rf ${DESTINATIONSITEDOCROOT}/wp-content/cache/* >/dev/null 2>&1

# Force HTTPS if not already.

if ! grep -q '# BigScoots Force HTTPS' /usr/local/nginx/conf/conf.d/"$DESTINATIONSITE".conf; then
        /bigscoots/wpo_forcehttps.sh "$DESTINATIONSITE"
fi

"$NGINX" -t > /dev/null 2>&1
    if [ $? -eq 0 ]; then
                npreload > /dev/null 2>&1
        else
                "$NGINX" -t 2>&1 | mail -s "WPO URGENT - Nginx conf fail during clone request - From: $SOURCESITE To: $DESTINATIONSITE  -  $HOSTNAME" monitor@bigscoots.com
                exit 1
    fi
