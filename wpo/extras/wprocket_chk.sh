#!/bin/bash

domain="${1}"

WPCLIFLAGS="--allow-root --skip-plugins --skip-themes --require=/bigscoots/includes/err_report.php"
sslconf=$(echo /usr/local/nginx/conf/conf.d/"${domain}".ssl.conf)
wpinstall=/home/nginx/domains/"${domain}"/public

if [ ! -d "${wpinstall}" ]; then
  echo "" | mail -s "WPO - wprocket_chk.sh failed - $domain doesn't exist on  $HOSTNAME" monitor@bigscoots.com
  exit 1
fi

if [ "{$2}" = -c ]; then
  if ! wp ${WPCLIFLAGS} plugin is-active wp-rocket --path="${wpinstall}"; then
    exit 5 # installed but not active
  fi
fi


if wp ${WPCLIFLAGS} plugin is-installed wp-rocket --path="${wpinstall}"; then

  if [ ! -d "/usr/local/nginx/conf/rocket-nginx" ]; then
    bringmeback=$(pwd)
    cd /usr/local/nginx/conf/ || exit
    git clone https://github.com/maximejobin/rocket-nginx.git
    cd rocket-nginx || exit
    cp rocket-nginx.ini.disabled rocket-nginx.ini
    php rocket-parser.php
    cd "$bringmeback" || exit
    reloadconfig=1
  fi

  if ! grep -q "rocket-nginx/default.conf" "${sslconf}" ; then
    sed -i '/rediscache_/a\ \ include /usr/local/nginx/conf/rocket-nginx/default.conf\;' "${sslconf}"
    reloadconfig=1
  fi

  if grep -q "#include /usr/local/nginx/conf/rocket-nginx/default.conf;" "${sslconf}" ; then
    sed -i 's/#include \/usr\/local\/nginx\/conf\/rocket-nginx\/default.conf;/include \/usr\/local\/nginx\/conf\/rocket-nginx\/default.conf;/g' "${sslconf}"
    reloadconfig=1
  fi

  for i in wpsupercache_ wpcacheenabler_ rediscache_ ; do
    if [[ ! $(grep $i "${sslconf}") =~ ^# ]]; then
      sed -i "/$i/s/#\?include /#include /g" "${sslconf}"
      reloadconfig=1
    fi
  done

  sed -i 's/#\?try_files /#try_files /g ; s/#try_files \$uri \$uri\/ \/index.php?\$/try_files \$uri \$uri\/ \/index.php?\$/g' "${sslconf}"

  if [ "${reloadconfig}" == 1 ]; then
  "$NGINX" -t > /dev/null 2>&1
    if [ $? -eq 0 ]; then
                npreload > /dev/null 2>&1
    else
                "$NGINX" -t 2>&1 | mail -s "WPO URGENT - Nginx conf fail when running wprocket_chk.sh on $domain -  $HOSTNAME" monitor@bigscoots.com
    fi
  fi
fi