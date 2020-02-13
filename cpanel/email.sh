#!/bin/bash

CPUSER=$2
DOMAIN=$3

case $1 in
list_emails)

# bash /bigscoots/cpanel/email.sh list_emails ${CPUSER} ${DOMAIN}

uapi --user="${CPUSER}" Email list_pops_with_disk domain="${DOMAIN}" maxaccounts=500

;;
create_email)

# bash /bigscoots/cpanel/email.sh create_email ${CPUSER} ${DOMAIN} ${EMAIL} ${PASSWORD}

EMAIL=$4
PASSWORD=$5

uapi --user="${CPUSER}" Email add_pop email="${EMAIL}" password="${PASSWORD}" quota=0 domain="${DOMAIN}" skip_update_db=1

;;
esac
