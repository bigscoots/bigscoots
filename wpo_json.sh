#!/bin/bash

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

pmaurl=$(grep "https://$HOSTNAME/[0-9]" /root/centminlogs/centminmod_phpmyadmin_install_*.log | sed -r "s/\x1B\[([0-9]{1,3}((;[0-9]{1,3})*)?)?[m|K]//g" | sed 's/$/\//g' | tr -d " \t\n\r")
pmauser=$(grep Username: /root/centminlogs/centminmod_phpmyadmin_install_*.log | awk '{print $2}')
pmapass=$(grep Password: /root/centminlogs/centminmod_phpmyadmin_install_*.log | awk '{print $2}')
pmadbuser=$(wp --allow-root config get DB_USER --path=/home/nginx/domains/"$domain"/public/)
pmadbpass=$(wp --allow-root config get DB_PASSWORD --path=/home/nginx/domains/"$domain"/public/)

vhostlog=$(grep -rl "FTP username created for $domain" /root/centminlogs/*wordpress_addvhost.log)
grep -v "FTP Passive" "$vhostlog" | grep -C2 "FTP mode" > /tmp/tmpftp.txt

ftphost=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1')
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

done

else

domain="$1"

if [[ ! -d /home/nginx/domains/"$domain" ]] ; then

  echo "The domain $domain doesn't exist."
  exit 1
fi

pmaurl=$(grep "https://$HOSTNAME/[0-9]" /root/centminlogs/centminmod_phpmyadmin_install_*.log | sed -r "s/\x1B\[([0-9]{1,3}((;[0-9]{1,3})*)?)?[m|K]//g" | sed 's/$/\//g' | tr -d " \t\n\r")
pmauser=$(grep Username: /root/centminlogs/centminmod_phpmyadmin_install_*.log | awk '{print $2}')
pmapass=$(grep Password: /root/centminlogs/centminmod_phpmyadmin_install_*.log | awk '{print $2}')
pmadbuser=$(wp --allow-root config get DB_USER --path=/home/nginx/domains/"$domain"/public/)
pmadbpass=$(wp --allow-root config get DB_PASSWORD --path=/home/nginx/domains/"$domain"/public/)

vhostlog=$(grep -rl "FTP username created for $domain" /root/centminlogs/*wordpress_addvhost.log)
grep -v "FTP Passive" "$vhostlog" | grep -C2 "FTP mode" > /tmp/tmpftp.txt

ftphost=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1')
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
