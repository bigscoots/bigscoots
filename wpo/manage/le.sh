#!/bin/bash
# The amazing automated lets encrypt issue script made by the one and only Prasul

DOMAIN=$1

yes | /usr/local/src/centminmod/addons/acmetool.sh acmeupdate

if grep -q "${DOMAIN}"-acme.cer /usr/local/nginx/conf/conf.d/"${DOMAIN}".ssl.conf; then
        echo "SSL already exists."
        exit 0
else        
		echo "Attempting to issue the SSL now."
        yes | /usr/local/src/centminmod/addons/acmetool.sh issue "${DOMAIN}" live > /root/.bigscoots/"${DOMAIN}".ssl.txt
        cat /root/.bigscoots/"${DOMAIN}".ssl.txt

        if grep -q 'issue skipped as ssl cert still valid' /root/.bigscoots/"${DOMAIN}".ssl.txt; then
                echo 'SSL already issued, check conf.. will automate this.'
                exit 0
        elif grep -q 'Cert success.' /root/.bigscoots/"${DOMAIN}".ssl.txt; then
        		echo "Certificate was issued Successfully!"
                grep "${DOMAIN}"-acme /root/.bigscoots/"${DOMAIN}".ssl.txt |head -3 > /root/.bigscoots/add.txt
                grep "${DOMAIN}"-acme /root/.bigscoots/"${DOMAIN}".ssl.txt |head -3
                echo "Adding certs to /usr/local/nginx/conf/conf.d/${DOMAIN}.ssl.conf"
                sed -i '/ssl_dhparam/r /root/.bigscoots/add.txt' /usr/local/nginx/conf/conf.d/"${DOMAIN}".ssl.conf && rm -f /root/.bigscoots/add.tx /root/.bigscoots/"${DOMAIN}".ssl.txt
                echo "Checkng nginx conf"
                if nginx -t > /dev/null 2>&1; then
                	echo "nginx conf good, reloading nginx now.."
                    npreload > /dev/null 2>&1
                else
                	echo "nginx conf failed, check ticket"
                    nginx -t 2>&1 | mail -s "WPO URGENT - Nginx conf fail during issueing SSL on ${DOMAIN}  -  $HOSTNAME" monitor@bigscoots.com
                    exit 1
				fi
        else
                echo " No certs found "
        fi
fi
