#!/bin/bash

# internal wpo migration

WPCLIFLAGS="--allow-root --skip-plugins --skip-themes --require=/bigscoots/includes/err_report.php"

if [ -z "$1" ]; then
  echo "Requires a domain."
  exit 1
fi

if [ -z "$2" ]; then
  echo "Requires a destination host."
  exit 1
fi

if ! grep -q "${REMOTEHOST}" /etc/csf/csf.allow; then
	echo "Whitelisting IP in CSF"
	csf -a "${REMOTEHOST}"
fi

####
DOMAIN="$1"
REMOTEHOST="$2"
####
DOCROOT=/home/nginx/domains/${DOMAIN}/public
REMOTEPORT=2222

echo
echo "Checking ${DOMAIN} exists on source."
echo

if [ -d "${DOCROOT}" ]; then
	echo "${DOMAIN} exists, checking if WordPress exists."
	if wp ${WPCLIFLAGS} core is-installed --path="${DOCROOT}"; then
		echo "WordPress exists..."
	else
		echo "WordPress doesn't exist, exiting..."
		exit 1
	fi
else
	echo "${DOMAIN} does not exist, exiting..."
	exit 1
fi

echo
echo "Checking SSH connection(requires SSH key)."
echo

if ssh -p ${REMOTEPORT} -oBatchMode=yes -oStrictHostKeyChecking=no "${REMOTEHOST}" "exit" >/dev/null 2>&1; then
	echo
	echo "Connection Successful."
	echo
else
	echo
	echo "Connection failed, make sure SSH key is on ${REMOTEHOST}"
	echo
fi


# destination
echo
echo "Checking to see if ${DOMAIN} already exists at ${REMOTEHOST}"
echo


if ssh -p ${REMOTEPORT} -oBatchMode=yes -oStrictHostKeyChecking=no "${REMOTEHOST}" "[ -d /home/nginx/domains/${DOMAIN} ]"; then
	echo
	echo "${DOMAIN} Exists, checking to see if it has a valid WordPress install."
	echo
	if ssh -p ${REMOTEPORT} -oBatchMode=yes -oStrictHostKeyChecking=no "${REMOTEHOST}" "wp ${WPCLIFLAGS} core is-installed --path=${DOCROOT}" >/dev/null 2>&1;then
		echo
		echo "WordPress is ready to go!"
		echo
	else
		echo
		echo "WordPress is not ready.  Fix it then rerun."
		echo
		exit 1
	fi

else
	echo
	echo "${DOMAIN} does not exist, creating ${DOMAIN} and wordpress install now."
	echo

	ssh -p ${REMOTEPORT} -oBatchMode=yes -oStrictHostKeyChecking=no "${REMOTEHOST}" "/bigscoots/wpo/manage/createdomain.sh ${DOMAIN}"

	echo
	echo
	echo
	echo
	echo
	echo
fi

echo
echo "Ensuring ${DOMAIN} exists on the destination server."
echo

if ssh -p ${REMOTEPORT} -oBatchMode=yes -oStrictHostKeyChecking=no "${REMOTEHOST}" "[ ! -d /home/nginx/domains/${DOMAIN} ]"; then
	echo
	echo "${DOMAIN} still doesnt exist on destiantion server, exiting."
	echo
	exit 1
else
	echo
	echo "${DOMAIN} exists, moving along..."
	echo 
fi


echo
echo "Pulling the destination DB Details from WodPress:"
echo

NEW_DB_NAME=$(ssh -p ${REMOTEPORT} -oBatchMode=yes -oStrictHostKeyChecking=no "${REMOTEHOST}" "wp ${WPCLIFLAGS} config get DB_NAME --path=${DOCROOT}")
echo "DB: ${NEW_DB_NAME}"

NEW_DB_USER=$(ssh -p ${REMOTEPORT} -oBatchMode=yes -oStrictHostKeyChecking=no "${REMOTEHOST}" "wp ${WPCLIFLAGS} config get DB_USER --path=${DOCROOT}")
echo "DB User: ${NEW_DB_USER}"

NEW_DB_PASSWORD=$(ssh -p ${REMOTEPORT} -oBatchMode=yes -oStrictHostKeyChecking=no "${REMOTEHOST}" "wp ${WPCLIFLAGS} config get DB_PASSWORD --path=${DOCROOT}")
echo "DB User Pass: ${NEW_DB_PASSWORD}"

echo
echo "Resetting the destination database."
echo

ssh -p ${REMOTEPORT} -oBatchMode=yes -oStrictHostKeyChecking=no "${REMOTEHOST}" "wp ${WPCLIFLAGS} db reset --yes --path=${DOCROOT}"

# source: 

echo
echo "Syncing the WordPress install."
echo

sleep 3

rsync -ahv -e "ssh -p ${REMOTEPORT}" --delete "${DOCROOT}"/ "${REMOTEHOST}":"${DOCROOT}"/

echo
echo "Syncing nginx conf..."
echo

rsync -ahv -e "ssh -p ${REMOTEPORT}" /usr/local/nginx/conf/conf.d/"${DOMAIN}".* "${REMOTEHOST}":/usr/local/nginx/conf/conf.d/

echo
echo "Syncing nginx includes..."
echo

rsync -ahv -e "ssh -p ${REMOTEPORT}" /usr/local/nginx/conf/wpincludes/"${DOMAIN}" "${REMOTEHOST}":/usr/local/nginx/conf/wpincludes/

echo
echo "Syncing SSL."
echo

rsync -ahv -e "ssh -p ${REMOTEPORT}" /usr/local/nginx/conf/ssl/"${DOMAIN}" "${REMOTEHOST}":/usr/local/nginx/conf/ssl/

echo
echo "Exporting and importing the database."
echo

WDPPREFIX=$(wp ${WPCLIFLAGS} config get table_prefix --path="${DOCROOT}")

if wp ${WPCLIFLAGS} db tables "${WDPPREFIX}swp_*" --format=csv --all-tables --path="${DOCROOT}" >/dev/null 2>&1; then
    wp ${WPCLIFLAGS} db export - --path="${DOCROOT}" --exclude_tables=$(wp ${WPCLIFLAGS} db tables "${WDPPREFIX}swp_*" --format=csv --all-tables --path="${DOCROOT}") --quiet --single-transaction --quick --lock-tables=false --max_allowed_packet=1G | wp ${WPCLIFLAGS} --quiet db import - --path="${DOCROOT}" --ssh="${REMOTEHOST}":"${REMOTEPORT}" --quiet --force --max_allowed_packet=1G
else
    wp ${WPCLIFLAGS} db export - --path="${DOCROOT}" --quiet --single-transaction --quick --lock-tables=false --max_allowed_packet=1G | wp ${WPCLIFLAGS} --quiet db import - --path="${DOCROOT}" --ssh="${REMOTEHOST}":"${REMOTEPORT}" --quiet --force --max_allowed_packet=1G    
fi

echo
echo "Lets do one final sync of the files..."
echo

rsync -ahv -e "ssh -p ${REMOTEPORT}" --delete "${DOCROOT}"/ "${REMOTEHOST}":"${DOCROOT}"/

echo
echo
echo
echo "Running wpo_theworks"
echo

ssh -p ${REMOTEPORT} -oBatchMode=yes -oStrictHostKeyChecking=no "${REMOTEHOST}" "cd ${DOCROOT}/ ; bash /bigscoots/wpo_theworks.sh"

echo
echo
echo
echo "Migrated completed!"
echo