#!/bin/bash

if [ -z "$1" ]; then
  echo "Requires a domain."
  exit 1
fi

# if [ -z "$2" ]; then
#   echo "Requires fresh or existing."
#   exit 1
# fi

domain="$1"
ftpuser="${domain//./}"
email=admin@"$domain"
WPCLIFLAGS="--allow-root --skip-plugins --skip-themes --require=/bigscoots/includes/err_report.php"

if [[ ${domain} == *"bigscoots-staging"* ]]; then
    email=admin@"$(echo $domain | sed '/\..*\./s/^[^.]*\.//')"
fi

domainip=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1\|192.168.')

if [ -d /home/nginx/domains/"$domain" ]; then
  echo "$domain already exists on the server."
  exit
fi

sed -i 's/openssl dhparam/#openssl dhparam/g' /usr/local/src/centminmod/inc/wpsetup.inc
sed -i 's/ssl_dhparam/#ssl_dhparam/g' /usr/local/src/centminmod/inc/wpsetup.inc

touch /etc/centminmod/custom_config.inc

if ! grep -q LETSENCRYPT_DETECT /etc/centminmod/custom_config.inc ;then
	echo "LETSENCRYPT_DETECT='y'" >> /etc/centminmod/custom_config.inc
fi

/bigscoots/wpo/manage/expect/createdomain "$domain" "$ftpuser" "$email"
touch /usr/local/nginx/conf/wpincludes/"$domain"/redirects.conf

sed -i "/\/usr\/local\/nginx\/conf\/503include-only.conf/a \  include \/usr\/local\/nginx\/conf\/wpincludes\/$domain\/redirects.conf;" /usr/local/nginx/conf/conf.d/"$domain".ssl.conf
sed -i 's/include \/usr\/local\/nginx\/conf\/autoprotect/#include \/usr\/local\/nginx\/conf\/autoprotect/g' /usr/local/nginx/conf/conf.d/"$domain".ssl.conf
sed -i 's/ssl_dhparam/#ssl_dhparam/g' /usr/local/nginx/conf/conf.d/"$domain".ssl.conf

if [ "$2" == fresh ]; then
  cd /home/nginx/domains/"$domain"/public || exit
  bash /bigscoots/wpo_theworks.sh fresh
fi


crontab -l | grep -v '/root/tools/wp_updater'  | crontab -

wp ${WPCLIFLAGS} plugin delete --all --path=/home/nginx/domains/"$domain"/public

sed "s/REPLACEDOMAIN/$domain/g ; s/REPLACEIP/$domainip/g" /bigscoots/wpo/extras/dnszone.txt > /home/nginx/domains/"$domain"/"$domain"-dnszone.txt

if [ -f /home/nginx/domains/"$domain"/.fresh ]; then
  cat /home/nginx/domains/"$domain"/.fresh | mail -s "$domain has been successfully created on  $HOSTNAME - DNS attached" -a /home/nginx/domains/"$domain"/"$domain"-dnszone.txt monitor@bigscoots.com
else
  echo "" | mail -s "$domain has been successfully created on  $HOSTNAME - DNS attached" -a /home/nginx/domains/"$domain"/"$domain"-dnszone.txt monitor@bigscoots.com
fi