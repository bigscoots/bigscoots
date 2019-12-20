#!/bin/bash


domain="${1}"

WPCLIFLAGS="--allow-root --skip-plugins --skip-themes --require=/bigscoots/includes/err_report.php"
sslconf=$(echo /usr/local/nginx/conf/conf.d/"${domain}".ssl.conf)
wpinstall=/home/nginx/domains/"${domain}"/public

if [ ! -d "${wpinstall}" ]; then
  echo "" | mail -s "WPO - wprocket_chk.sh failed - $domain doesn't exist on  $HOSTNAME" monitor@bigscoots.com
  exit 1
fi

if [ -d "${wpinstall}/wp-content/plugins/wp-rocket" ]; then

  wprocket=y

  if [ ! -d "/usr/local/nginx/conf/rocket-nginx" ]; then

    bringmeback=$(pwd)
    cd /usr/local/nginx/conf/ || exit
    git clone https://github.com/maximejobin/rocket-nginx.git
    cd rocket-nginx || exit
    cp rocket-nginx.ini.disabled rocket-nginx.ini
    php rocket-parser.php
    cd "$bringmeback" || exit

  fi

  if ! grep -q "rocket-nginx/default.conf" "${sslconf}" ; then

    sed -i '/rediscache_/a\ \ include /usr/local/nginx/conf/rocket-nginx/default.conf\;' "${sslconf}"

  fi

  sed -i 's/#include \/usr\/local\/nginx\/conf\/rocket-nginx\/default.conf;/include \/usr\/local\/nginx\/conf\/rocket-nginx\/default.conf;/g' "${sslconf}"

  for i in wpsupercache_ wpcacheenabler_ rediscache_ ; do

    if [[ ! $(grep $i "${sslconf}") =~ ^# ]]; then

      sed -i "/$i/s/#\?include /#include /g" "${sslconf}"

    fi

  done

  sed -i 's/#\?try_files /#try_files /g ; s/#try_files \$uri \$uri\/ \/index.php?\$/try_files \$uri \$uri\/ \/index.php?\$/g' "${sslconf}"

else

wp ${WPCLIFLAGS} plugin install cache-enabler --activate --path="${wpinstall}" --quiet ; wp ${WPCLIFLAGS} plugin delete comet-cache sg-cachepress wp-hummingbird wp-super-cache w3-total-cache nginx-helper wp-redis wp-fastest-cache --path="${wpinstall}" --quiet

fi

sed -i 's=#include /usr/local/nginx/conf/cloudflare.conf;=include /usr/local/nginx/conf/cloudflare.conf;=g' /usr/local/nginx/conf/conf.d/"$(pwd | sed 's/\// /g' | awk '{print $4}')".ssl.conf
