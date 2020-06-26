#!/bin/bash

BSPATH=/root/.bigscoots
WPCLIFLAGS="--allow-root --skip-plugins --skip-themes --require=/bigscoots/includes/err_report.php"

{

if [ ! -f "/root/.wpocf" ] || [ ! -s "/root/.wpocf" ]
 then
    {
        echo "\"cloudflare\": {"
        echo "\"username\": \"NA\","
        echo "\"password\": \"NA\","
        echo "\"userKey\": \"NA\","
        echo "\"apiKey\": \"NA\","
        echo "\"nameserver1\": \"NA.ns.cloudflare.com\","
        echo "\"nameserver2\": \"NA.ns.cloudflare.com\""
    } >> /root/.wpocf

  else
    :
 fi


if [ ! -d /usr/local/nginx/html/*mysqladmin* ]; then
  cd /usr/local/src/centminmod/addons 
  wget --no-check-certificate https://github.com/centminmod/phpmyadmin/raw/master/phpmyadmin.sh -O phpmyadmin.sh
  chmod 0700 /usr/local/src/centminmod/addons/phpmyadmin.sh
  bash phpmyadmin.sh install
  if [ ! -d /usr/local/nginx/html/*mysqladmin* ]; then
    rm -f /usr/local/nginx/conf/phpmyadmin_check
    rm -f /usr/local/nginx/conf/conf.d/phpmyadmin_ssl.conf
    bash /usr/local/src/centminmod/addons/phpmyadmin.sh install
    if [ ! -d /usr/local/nginx/html/*mysqladmin* ]; then
        echo "" | mail -s "WPO /bigscoots/wpo_json.sh failed because of phpmyadmin -  $HOSTNAME" monitor@bigscoots.com
        exit
    fi
  fi
  sed -i 's/listen 443 ssl spdy/listen 443 ssl http2/g' /usr/local/nginx/conf/conf.d/phpmyadmin_ssl.conf
  sed -i 's/spdy_headers_comp/#spdy_headers_comp/g' /usr/local/nginx/conf/conf.d/phpmyadmin_ssl.conf
  sed -i 's/return 302/#return 302/g' /usr/local/nginx/conf/conf.d/phpmyadmin_ssl.conf
  sed -i 's/#include \/usr\/local\/nginx\/conf\/php.conf/include \/usr\/local\/nginx\/conf\/php.conf/g' /usr/local/nginx/conf/conf.d/phpmyadmin_ssl.conf
fi < /dev/null > /dev/null 2>&1

pmadirectory=$(echo /usr/local/nginx/html/*mysqladmin* | sed 's/\/usr\/local\/nginx\/html\///g' | head -1)

if [ -z "$1" ]

then

grep -l "The servers opcache has been flushed" /usr/local/nginx/html/*.php | sed 's/\// /'g | grep -oE '[^ ]+$' > /dev/null
opcachechk=$?
if [ "$opcachechk" -ne 0 ]; then
    opcachephp=$(cat /dev/urandom | tr -cd 'a-f0-9' | head -c 32).php ;
{
  echo "<?php"
  echo "echo 'The servers opcache has been flushed.';"
  echo "opcache_reset();"
  echo "?>"

} >> "/usr/local/nginx/html/$opcachephp"
chown nginx: "/usr/local/nginx/html/$opcachephp"

sed -i 's/return 302/#return 302/g' /usr/local/nginx/conf/conf.d/phpmyadmin_ssl.conf
sed -i 's/#include \/usr\/local\/nginx\/conf\/php.conf/include \/usr\/local\/nginx\/conf\/php.conf/g' /usr/local/nginx/conf/conf.d/phpmyadmin_ssl.conf

fi

for domain in $(\ls /home/nginx/domains/) ; do

pmaurl=$(grep "https://$HOSTNAME/[0-9]" $(grep -rl $(echo /usr/local/nginx/html/*mysqladmin* | sed 's/\/usr\/local\/nginx\/html\///g' | head -1) /root/centminlogs/centminmod_phpmyadmin_install_*.log) | sed -r "s/\x1B\[([0-9]{1,3}((;[0-9]{1,3})*)?)?[m|K]//g" | sed 's/$/\//g' | tr -d " \t\n\r")
pmauser=$(grep Username: $(grep -rl $(echo /usr/local/nginx/html/*mysqladmin* | sed 's/\/usr\/local\/nginx\/html\///g' | head -1) /root/centminlogs/centminmod_phpmyadmin_install_*.log) | awk '{print $2}')
pmapass=$(grep Password: $(grep -rl $(echo /usr/local/nginx/html/*mysqladmin* | sed 's/\/usr\/local\/nginx\/html\///g' | head -1) /root/centminlogs/centminmod_phpmyadmin_install_*.log) | awk '{print $2}')
pmadbuser=$(wp ${WPCLIFLAGS} config get DB_USER --path=/home/nginx/domains/"$domain"/public/)
pmadbpass=$(wp ${WPCLIFLAGS} config get DB_PASSWORD --path=/home/nginx/domains/"$domain"/public/)

vhostlog=$(grep -l "FTP username created for $domain" /root/centminlogs/centminmod*addvhost.log | xargs ls -rt | tail -1)
grep -v "FTP Passive" "$vhostlog" | grep -C2 "FTP mode" > /tmp/tmpftp.txt

ftphost=$(ip route get 1 | awk '{print $NF;exit}')
ftpusername=$(grep "FTP username created for $domain" "$vhostlog" | grep -oE '[^ ]+$')
ftppassword=$(grep "FTP password auto generated:" "$vhostlog" | grep -oE '[^ ]+$' | sed 's/\\/\\\\/g' | sed 's/"/\\"/g')

if [ ! -d "${BSPATH}" ]; then
  mkdir -p "$BSPATH"
  touch "$BSPATH"/backupinfo
fi

if [ -f /proc/vz/veinfo ]; then
  if grep -q bkuser= "${BSPATH}"/backupinfo; then
    BKUSER=$(grep bkuser= "${BSPATH}"/backupinfo | sed 's/=/ /g' | awk '{print $2}')
  else
  BKUSER=wpo$(awk '{print $1}' /proc/vz/veinfo)
  fi
elif [[ ${HOSTNAME} =~ bigscoots-wpo.com ]]; then
 BKUSER=wpo$(hostname -s)
else
  BKUSER=wpo"${HOSTNAME//./}"
fi

if ! grep -q bkuser= "${BSPATH}"/backupinfo; then 
  echo bkuser="${BKUSER}" >> "${BSPATH}"/backupinfo
fi

rm -f /tmp/tmpftp.txt

sleep 1

echo ; echo { ; echo "\"domain\": \"$domain\"," ; echo "\"backupUser\": \"$bkuser\"," ; echo "\"serverIP\": \"$ftphost\"," ; echo "\"flushOpcacheURL\": \"https://$HOSTNAME/$(grep -l "The servers opcache has been flushed" /usr/local/nginx/html/*.php | sed 's/\// /'g | grep -oE '[^ ]+$')\"," ; echo "\"phpMyAdmin\": {" ; echo "\"url\": \"$pmaurl\"," ; echo "\"popupUsername\": \"$pmauser\"," ; echo "\"popupPassword\": \"$pmapass\"," ; echo "\"username\": \"$pmadbuser\"," ; echo "\"password\": \"$pmadbpass\"" ; echo }, ; echo "\"ftp\": {" ; echo "\"host\": \"$ftphost\"," ; echo "\"port\": \"21\"," ; echo "\"mode\": \"FTP (explicit SSL)\"," ; echo "\"pasv\": \"Ensure is Checked/Enabled\"," ; echo "\"username\": \"$ftpusername\"," ; echo "\"password\": \"$ftppassword\"" ; echo } ; if [ "$2" = cf ] ; then cat /root/.wpocf ; echo } ; fi ; echo } ; echo

done

else

domain="$1"

if [[ ! -d /home/nginx/domains/"$domain" ]] ; then

  echo "The domain $domain doesn't exist."
  exit 1
fi

pmaurl=$(grep "https://$HOSTNAME/[0-9]" $(grep -rl $(echo /usr/local/nginx/html/*mysqladmin* | sed 's/\/usr\/local\/nginx\/html\///g' | head -1) /root/centminlogs/centminmod_phpmyadmin_install_*.log) | sed -r "s/\x1B\[([0-9]{1,3}((;[0-9]{1,3})*)?)?[m|K]//g" | sed 's/$/\//g' | tr -d " \t\n\r")
pmauser=$(grep Username: $(grep -rl $(echo /usr/local/nginx/html/*mysqladmin* | sed 's/\/usr\/local\/nginx\/html\///g' | head -1) /root/centminlogs/centminmod_phpmyadmin_install_*.log) | awk '{print $2}')
pmapass=$(grep Password: $(grep -rl $(echo /usr/local/nginx/html/*mysqladmin* | sed 's/\/usr\/local\/nginx\/html\///g' | head -1) /root/centminlogs/centminmod_phpmyadmin_install_*.log) | awk '{print $2}')
pmadbuser=$(wp ${WPCLIFLAGS} config get DB_USER --path=/home/nginx/domains/"$domain"/public/)
pmadbpass=$(wp ${WPCLIFLAGS} config get DB_PASSWORD --path=/home/nginx/domains/"$domain"/public/)

vhostlog=$(grep -l "FTP username created for $domain" /root/centminlogs/centminmod*addvhost.log | xargs ls -rt | tail -1)
grep -v "FTP Passive" "$vhostlog" | grep -C2 "FTP mode" > /tmp/tmpftp.txt

ftphost=$(ip route get 1 | awk '{print $NF;exit}')
ftpusername=$(grep "FTP username created for $domain" "$vhostlog" | grep -oE '[^ ]+$')
ftppassword=$(grep "FTP password auto generated:" "$vhostlog" | grep -oE '[^ ]+$' | sed 's/\\/\\\\/g' | sed 's/"/\\"/g')

if ! awk '{print $1}' /proc/vz/veinfo > /dev/null 2>&1 ; then
     bkuser=wpo
     else
     bkuser=$(echo wpo$(awk '{print $1}' /proc/vz/veinfo))
fi

rm -f /tmp/tmpftp.txt

sleep 1

echo ; echo { ; echo "\"domain\": \"$domain\"," ; echo "\"backupUser\": \"$bkuser\"," ; echo "\"serverIP\": \"$ftphost\"," ; echo "\"flushOpcacheURL\": \"https://$HOSTNAME/$(grep -l "The servers opcache has been flushed" /usr/local/nginx/html/*.php | sed 's/\// /'g | grep -oE '[^ ]+$')\"," ; echo "\"phpMyAdmin\": {" ; echo "\"url\": \"$pmaurl\"," ; echo "\"popupUsername\": \"$pmauser\"," ; echo "\"popupPassword\": \"$pmapass\"," ; echo "\"username\": \"$pmadbuser\"," ; echo "\"password\": \"$pmadbpass\"" ; echo }, ; echo "\"ftp\": {" ; echo "\"host\": \"$ftphost\"," ; echo "\"port\": \"21\"," ; echo "\"mode\": \"FTP (explicit SSL)\"," ; echo "\"pasv\": \"Ensure is Checked/Enabled\"," ; echo "\"username\": \"$ftpusername\"," ; echo "\"password\": \"$ftppassword\"" ; echo } ; if [ "$2" = cf ] ; then cat /root/.wpocf ; echo } ; fi ; echo } ; echo

fi

} 2> /dev/null
