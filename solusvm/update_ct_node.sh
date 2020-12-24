#!/bin/bash

NODEIP=$1
DBNAME=$(sed 's/:/ /g' /usr/local/solusvm/includes/solusvm.conf | awk '{print $1}')
DBUSER=$(sed 's/:/ /g' /usr/local/solusvm/includes/solusvm.conf | awk '{print $2}')
DBPASS=$(sed 's/:/ /g' /usr/local/solusvm/includes/solusvm.conf | awk '{print $3}')
NODEID=$(mysql -u "${DBUSER}" -p"${DBPASS}" "${DBNAME}" -sNe "SELECT nodeid FROM nodes WHERE ip LIKE '$NODEIP'")

while read -r CTID; do
        VSERVERID=$(mysql -u "${DBUSER}" -p"${DBPASS}" "${DBNAME}" -sNe "SELECT vserverid  FROM vservers WHERE ctid = $CTID")
        /scripts/vm-migrate "$VSERVERID" "$NODEID"
done < <(ssh -p 2222 -oBatchMode=yes -oStrictHostKeyChecking=no "$NODEIP" "/usr/sbin/vzlist -H -o ctid")