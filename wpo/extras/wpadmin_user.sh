#!/bin/bash
# Add WordPress Admin User Or Update w/ New Password

# TODO:
# Multisite Support Needed

WPUSERNAME='bigscoots'
WPEMAIL='noreply@bigscoots.com'
WPEMAIL_BACKUP='noreply+2@bigscoots.com'
WPPASSWORD=$(cat /dev/urandom | tr -dc A-Za-z0-9 | head -c 20)

WPCLIFLAGS="--allow-root --skip-plugins --skip-themes"

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

# Fetch SiteURL / Check WP
SITEURL=$(wp ${WPCLIFLAGS} option get siteurl 2>/dev/null)

# Ensure Path is WP
if [[ ! $? -eq 0 ]]; then
    echo -e "${RED}FAILURE:${NC} Unable to locate WordPress site."
    exit 1
fi

# Create User
function WP_USER_CREATE () {
    WPUSERCREATE=$(wp ${WPCLIFLAGS} user create "${WPUSERNAME}" "${WPEMAIL}" --role=administrator --user_pass="${WPPASSWORD}" >/dev/null 2>&1)
    # If User Creation Exit Status == 0 (Creation Successful); Output PW; Else; Check if Email In-Use
    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}Success:${NC} The '${WPUSERNAME}' user was created on ${SITEURL}"
        echo "Password: ${WPPASSWORD}"
    else
        WPEMAILCHECK=$(wp ${WPCLIFLAGS} user list --field=user_email | grep "${WPEMAIL}" >/dev/null 2>&1)
        # If Email Check Exit Status == 0 (Email Exists); Switch to Secondary Email & Re-Run Function; Else; Output Failure
        if [[ $? -eq 0 ]]; then
            WPEMAIL=${WPEMAIL_BACKUP}
            WP_USER_CREATE
        else
            echo -e "${RED}FAILURE:${NC} The '${WPUSERNAME}' user could not be created on ${SITEURL}"
            exit 1
        fi
    fi
}

# Update User
function WP_USER_UPDATE () {
    WPUSERUPDATE=$(wp ${WPCLIFLAGS} user update "${WPUSERNAME}" --user_pass="${WPPASSWORD}" --role=administrator >/dev/null 2>&1)
    # If User Update Exit Status == 0 (Update Successful); Output PW; Else; Output Failure
    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}Success:${NC} The '${WPUSERNAME}' user was updated on ${SITEURL}"
        echo "New Password: ${WPPASSWORD}"
    else
        echo -e "${RED}FAILURE:${NC} The '${WPUSERNAME}' user could not be updated on ${SITEURL}"
        exit 1
    fi
}

# Check if WP User Exists
WPUSERCHECK=$(wp ${WPCLIFLAGS} user get ${WPUSERNAME} >/dev/null 2>&1)

# If User Check Exit Status == 0 (User Exists); Update User; Else; Create User
if [[ $? -eq 0 ]]; then
    WP_USER_UPDATE
else
    WP_USER_CREATE
fi