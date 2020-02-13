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
delete_email)

# bash /bigscoots/cpanel/email.sh delete_email ${CPUSER} ${DOMAIN} ${EMAIL}

EMAIL=$4

uapi --user="${CPUSER}" Email delete_pop email="${EMAIL}" domain="${DOMAIN}"

;;
passwd_email)

# bash /bigscoots/cpanel/email.sh passwd_email ${CPUSER} ${DOMAIN} ${EMAIL} ${PASSWORD}

EMAIL=$4
PASSWORD=$5

uapi --user="${CPUSER}" Email passwd_pop email="${EMAIL}" password="${PASSWORD}" domain="${DOMAIN}"

;;
addfwd_email)

# bash /bigscoots/cpanel/email.sh addfwd_email ${CPUSER} ${DOMAIN} ${EMAIL} ${FWDTOEMAIL}

EMAIL=$4
FWDTOEMAIL=$5
FULLEMAIL=$(echo ${EMAIL}@${DOMAIN})

uapi --user="${CPUSER}" Email add_forwarder domain="${DOMAIN}" email="${FULLEMAIL}" fwdopt=fwd fwdemail="${FWDTOEMAIL}"

;;
delfwd_email)

# bash /bigscoots/cpanel/email.sh delfwd_email ${CPUSER} ${DOMAIN} ${EMAIL} ${FWDTOEMAIL}

EMAIL=$4
FWDTOEMAIL=$5
FULLEMAIL=$(echo ${EMAIL}@${DOMAIN})

uapi --user="${CPUSER}" Email delete_forwarder address="${FULLEMAIL}" forwarder="${FWDTOEMAIL}"

;;
esac
