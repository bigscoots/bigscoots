#!/bin/bash

if [ -z "$1" ]; then
  echo "Requires a domain."
  exit 1
fi

if [[ $1 == check ]]; then 
  if [ ! -f /root/.bigscoots/wpo.installed ]; then 
    exit 1
  else
    exit 0
  fi
fi

# if [ -z "$2" ]; then
#   echo "Requires fresh or existing."
#   exit 1
# fi

domain="$1"
ftpuser="${domain//./}"
if [[ $domain == *.*.* ]]; then
  email=admin@${domain#*.}
else
  email=admin@"$domain"
fi
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

if ! grep -q block-all-mixed-content /usr/local/nginx/conf/conf.d/"$domain".ssl.conf >/dev/null 2>&1; then 
  sed -i '/# before enabling HSTS/ a \  add_header Content-Security-Policy \"block-all-mixed-content;\";' /usr/local/nginx/conf/conf.d/"$domain".ssl.conf
fi

sed -i '/^location ~ \^\/wp-content\/uploads\/ {$/,/^}/d' /usr/local/nginx/conf/wpincludes/"$domain"/wpsecure_"$domain".conf

cd /home/nginx/domains/"$domain"/public || exit
wp ${WPCLIFLAGS} plugin uninstall --all --deactivate --path=/home/nginx/domains/"$domain"/public >/dev/null 2>&1

if [ "$2" == fresh ]; then
  if [ "$3" == skipcache ]; then 
    bash /bigscoots/wpo_theworks.sh fresh skipcache
  else
    bash /bigscoots/wpo_theworks.sh fresh
  fi
fi

if [ ! -f /usr/local/nginx/conf/xmlrpcblock.conf ]; then
{
echo     allow 192.0.64.0/18\;
echo     deny all\;
} >> /usr/local/nginx/conf/xmlrpcblock.conf
fi

/bigscoots/wpo/extras/phplogging.sh

crontab -l | grep -v '/root/tools/wp_updater'  | crontab -