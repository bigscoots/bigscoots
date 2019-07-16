#!/bin/bash

if [ ! -f "/root/.wpocf" ] || [ ! -s "/root/.wpocf" ]
 then
    {
        echo "\"cloudflare_username\": \"NA\","
        echo "\"cloudflare_password\": \"NA\","
        echo "\"cloudflare_userkey\": \"NA\","
        echo "\"cloudflare_apikey\": \"NA\","
        echo "\"cloudflare_nameserver_1\": \"NA.ns.cloudflare.com\","
        echo "\"cloudflare_nameserver_2\": \"NA.ns.cloudflare.com\""
    } >> /root/.wpocf

  else
    :
 fi

if [ -z "$1" ]

then

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

bkuser=$(echo wpo$(awk '{print $1}' /proc/vz/veinfo))

rm -f /tmp/tmpftp.txt

sleep 1

echo ; echo { ; echo "\"domain_name\": \"$domain\"," ; echo "\"backup_user\": \"$bkuser\"," ; echo "\"server_ip\": \"$ftphost\"," ; echo "\"opcache_url\": \"https://$HOSTNAME/$(grep -l "The servers opcache has been flushed" /usr/local/nginx/html/*.php | sed 's/\// /'g | grep -oE '[^ ]+$')\"," ; echo "\"phpMyAdmin_url\": \"$pmaurl\"," ; echo "\"phpMyAdmin_popup_username\": \"$pmauser\"," ; echo "\"phpMyAdmin_popup_password\": \"$pmapass\"," ; echo "\"phpMyAdmin_username\": \"$pmadbuser\"," ; echo "\"phpMyAdmin_password\": \"$pmadbpass\"," ; echo "\"ftp_host\": \"$ftphost\"," ; echo "\"ftp_port\": \"21\"," ; echo "\"ftp_mode\": \"FTP (explicit SSL)\"," ; echo "\"ftp_pasv\": \"Ensure is Checked/Enabled\"," ; echo "\"ftp_username\": \"$ftpusername\"," ; echo "\"ftp_password\": \"$ftppassword\"," ; cat /root/.wpocf ; echo } ; echo

done

else

:

fi
