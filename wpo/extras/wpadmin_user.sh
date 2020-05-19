#!/bin/bash
# Add WordPress Admin User Or Update w/ New Password

# TODO:
# Multisite Support Needed

WPUSERNAME='bigscoots'
WPEMAIL='noreply@bigscoots.com'
PASSWORD=$(cat /dev/urandom | tr -dc A-Za-z0-9 | head -c 20)

WPCLIFLAGS="--allow-root --skip-plugins --skip-themes"

# Ensure WP Exists
# if [[ ! -f 'wp-config.php' ]]; then
 if ! wp ${WPCLIFLAGS} core is-installed >/dev/null 2>&1; then
    echo "FAILURE! Unable to locate WordPress in current directory."
    exit 1
fi

# User Checker
WPUSERCHECK=$(wp ${WPCLIFLAGS} user get ${WPUSERNAME} >/dev/null 2>&1)

# If User Checker Exit Status != 0; Create User; Else; Update User
if [[ ! $? -eq 0 ]]; then
    WPUSERCREATE=$(wp ${WPCLIFLAGS} user create "${WPUSERNAME}" "${WPEMAIL}" --role=administrator --user_pass="${PASSWORD}" >/dev/null 2>&1)
    if [[ ! $? -eq 0 ]]; then
        echo "FAILURE! The '${WPUSERNAME}' user could not be created."
        exit 1
    else
        echo "Success! The '${WPUSERNAME}' user was created."
        echo "Password: ${PASSWORD}"
    fi
else
    echo "Success! The '${WPUSERNAME}' user was updated."
    WPUSERUPDATE=$(wp ${WPCLIFLAGS} user update "${WPUSERNAME}" --user_pass="${PASSWORD}" >/dev/null 2>&1)
    echo "New Password: ${PASSWORD}"
fi
