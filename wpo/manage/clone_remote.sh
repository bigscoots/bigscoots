#!/bin/bash

#
# Justin Catello - bigscoots.com
#

SOURCESITE="$1"
DESTINATIONSITE="$2"
BSPATH=/root/.bigscoots
REMOTEHOST="$3"
REMOTEPORT=2222

WPCLIFLAGS="--allow-root --skip-plugins --skip-themes --require=/bigscoots/includes/err_report.php"
NGINX=$(which nginx)

SOURCESITEDOCROOT=/home/nginx/domains/"${SOURCESITE}"/public
DESTINATIONSITEDOCROOT=/home/nginx/domains/"${DESTINATIONSITE}"/public

echo "Whitelisting IP in firewall."
if [ -f /etc/csf/csf.allow ] && ! grep -q "$REMOTEHOST" /etc/csf/csf.allow; then 
    csf -a "$REMOTEHOST" >/dev/null 2>&1
fi
echo "Done."

echo "Checking SSH connection."
if ! ssh -oBatchMode=yes -oStrictHostKeyChecking=no -p "$REMOTEPORT" "$REMOTEHOST" 'exit'; then
    echo "SSH: Connection to $REMOTEHOST over port $REMOTEPORT failed."
    exit
fi
echo "Done."

echo "Checking that WP installs exist at the source and destination."
if ! wp ${WPCLIFLAGS} core is-installed --path="${SOURCESITEDOCROOT}" --ssh="${REMOTEHOST}":"${REMOTEPORT}" && ! wp ${WPCLIFLAGS} core is-installed --path="${DESTINATIONSITEDOCROOT}" ; then
	echo "${SOURCESITE} or ${DESTINATIONSITE} does not exist."
    exit
fi
echo "Done."

echo "Getting the source sites database name."
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
echo "Done."

echo "Getting the destination sites database name."
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
echo "Done."


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


echo "Running rsync now."
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
echo "Done."

echo "Getting domain of destination site."
DESTINATIONSITEREPLACE=$(wp ${WPCLIFLAGS} option get siteurl --path="${DESTINATIONSITEDOCROOT}" --quiet | sed -r 's/https?:\/\///g')
echo "$DESTINATIONSITEREPLACE done."

echo "Getting DB user of source site."
SOURCESITEDBUSER=$(wp ${WPCLIFLAGS} config get DB_USER --path="${SOURCESITEDOCROOT}" --ssh="${REMOTEHOST}":"${REMOTEPORT}")
echo "$SOURCESITEDBUSER done."

echo "Getting DB user of destination site."
DESTINATIONSITEDBUSER=$(wp ${WPCLIFLAGS} config get DB_USER --path="${DESTINATIONSITEDOCROOT}")
echo "$DESTINATIONSITEDBUSER done."

echo "Getting db prefix of source site."
WDPPREFIX=$(wp ${WPCLIFLAGS} config get table_prefix --path="${SOURCESITEDOCROOT}" --ssh="${REMOTEHOST}":"${REMOTEPORT}")
echo "$WDPPREFIX done."

echo "Resetting database on destination site"
wp ${WPCLIFLAGS} db reset --yes --path="${DESTINATIONSITEDOCROOT}" --quiet
echo "Done."

echo "Exporting and importing database."
if wp ${WPCLIFLAGS} db tables "${WDPPREFIX}swp_*" --format=csv --all-tables --path="${SOURCESITEDOCROOT}" --ssh="${REMOTEHOST}":"${REMOTEPORT}" >/dev/null 2>&1; then
    wp ${WPCLIFLAGS} db export - --path="${SOURCESITEDOCROOT}" --ssh="${REMOTEHOST}":"${REMOTEPORT}" --exclude_tables=$(wp ${WPCLIFLAGS} db tables "${WDPPREFIX}swp_*" --format=csv --all-tables --path="${SOURCESITEDOCROOT}" --ssh="${REMOTEHOST}":"${REMOTEPORT}") --quiet --single-transaction --quick --lock-tables=false --max_allowed_packet=1G --default-character-set=utf8mb4 | sed "s/DEFINER=\`${SOURCESITEDBUSER}\`/DEFINER=\`${DESTINATIONSITEDBUSER}\`/g" | wp ${WPCLIFLAGS} --quiet db import - --path="${DESTINATIONSITEDOCROOT}" --quiet --force --max_allowed_packet=1G
else
    wp ${WPCLIFLAGS} db export - --path="${SOURCESITEDOCROOT}" --ssh="${REMOTEHOST}":"${REMOTEPORT}" --quiet --single-transaction --quick --lock-tables=false --max_allowed_packet=1G --default-character-set=utf8mb4 | sed "s/DEFINER=\`${SOURCESITEDBUSER}\`/DEFINER=\`${DESTINATIONSITEDBUSER}\`/g" | wp ${WPCLIFLAGS} --quiet db import - --path="${DESTINATIONSITEDOCROOT}" --quiet --force --max_allowed_packet=1G    
fi
echo "Done."

echo "Setting db table prefix on destination site."
wp ${WPCLIFLAGS} config set table_prefix ${WDPPREFIX} --path="${DESTINATIONSITEDOCROOT}" --quiet
echo "Done."

if wp ${WPCLIFLAGS} config get WP_SITEURL --path="${SOURCESITEDOCROOT}" --ssh="${REMOTEHOST}":"${REMOTEPORT}" >/dev/null 2>&1; then

 WPCONFIGWPSITEURL=$(wp ${WPCLIFLAGS} config get WP_SITEURL --path="${SOURCESITEDOCROOT}" --ssh="${REMOTEHOST}":"${REMOTEPORT}" --quiet | sed -r 's/https?:\/\///g')
 WPDBWPSITEURL=$(wp ${WPCLIFLAGS} db query "SELECT option_value FROM "${WDPPREFIX}"options WHERE option_name = 'siteurl';" --skip-column-names --path="${SOURCESITEDOCROOT}" --ssh="${REMOTEHOST}":"${REMOTEPORT}" | sed -r 's/https?:\/\///g')

    if  [ ! "$WPCONFIGWPSITEURL" == "$WPDBWPSITEURL" ]; then
      wp ${WPCLIFLAGS} search-replace "$WPDBWPSITEURL" "$DESTINATIONSITEREPLACE" --recurse-objects --skip-columns=guid --skip-tables="${WDPPREFIX}"users --path="${DESTINATIONSITEDOCROOT}" --quiet
    fi

fi

echo "Getting SITEURL of source site."
SITEURLSOURCE=$(wp ${WPCLIFLAGS} option get siteurl --path="${SOURCESITEDOCROOT}" --ssh="${REMOTEHOST}":"${REMOTEPORT}" --quiet | sed -r 's/https?:\/\///g')
echo "$SITEURLSOURCE done."

echo "Running search/replace on $SITEURLSOURCE to $DESTINATIONSITEREPLACE"
wp ${WPCLIFLAGS} search-replace "$SITEURLSOURCE" "$DESTINATIONSITEREPLACE" --recurse-objects --skip-columns=guid --skip-tables="${WDPPREFIX}"users --path="${DESTINATIONSITEDOCROOT}" --quiet
echo "Done."

echo "Checking for wp-rocket"
if [ -d "$DESTINATIONSITEDOCROOT/wp-content/plugins/wp-rocket" ]; then

    if wp ${WPCLIFLAGS} plugin is-active wp-rocket --path="${DESTINATIONSITEDOCROOT}"; then 
        rm -f "$DESTINATIONSITEDOCROOT"/wp-content/advanced-cache.php
        wp plugin ${WPCLIFLAGS} deactivate wp-rocket --path="${DESTINATIONSITEDOCROOT}"
        wp plugin ${WPCLIFLAGS} activate wp-rocket --path="${DESTINATIONSITEDOCROOT}"
    fi
fi
echo "Done."

echo "Updating .user.ini if found"
if [ -f "$DESTINATIONSITEDOCROOT"/.user.ini ]; then
    sed -i "s/$SOURCESITE/$DESTINATIONSITE/g" "$DESTINATIONSITEDOCROOT"/.user.ini
fi
echo "Done."

echo "Flushing elementor cache if any"
if wp ${WPCLIFLAGS} plugin is-installed elementor --path="${DESTINATIONSITEDOCROOT}" >/dev/null 2>&1; then
    wp ${WPCLIFLAGS} elementor flush_css --skip-plugins=$(wp ${WPCLIFLAGS} plugin list --format=csv --field=name --path="${DESTINATIONSITEDOCROOT}" | paste -s -d, - | sed -r 's/,?elementor//g') --path="${DESTINATIONSITEDOCROOT}"
fi
echo "Done."

echo "Chowning files at destination"
chown -R nginx: /home/nginx/domains/$DESTINATIONSITE &
echo "Done."
# Clear All Cache

echo "Clearing all cache"
! command -v redis-cli  >/dev/null 2>&1 || redis-cli flushall  >/dev/null 2>&1
[ -d ${DESTINATIONSITEDOCROOT}/wp-content/cache ] && rm -rf ${DESTINATIONSITEDOCROOT}/wp-content/cache/* >/dev/null 2>&1
echo "Done."
# Force HTTPS if not already.

echo "Forcing https if not already"
if ! grep -q '# BigScoots Force HTTPS' /usr/local/nginx/conf/conf.d/"$DESTINATIONSITE".conf; then
        /bigscoots/wpo_forcehttps.sh "$DESTINATIONSITE"
fi
echo "Done."

echo "Testing nginx config"
"$NGINX" -t > /dev/null 2>&1
    if [ $? -eq 0 ]; then
                npreload > /dev/null 2>&1
        else
                "$NGINX" -t 2>&1 | mail -s "WPO URGENT - Nginx conf fail during clone request - From: $SOURCESITE To: $DESTINATIONSITE  -  $HOSTNAME" monitor@bigscoots.com
                exit 1
    fi
echo "Done."

echo "Migration has been completed."