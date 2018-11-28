#!/bin/bash

if [ -z "$1" ]

then

for domain in $(\ls /home/nginx/domains/) ; do

pmaurl=$(grep "https://$HOSTNAME/[0-9]" /root/centminlogs/centminmod_phpmyadmin_install_*.log | sed -r "s/\x1B\[([0-9]{1,3}((;[0-9]{1,3})*)?)?[m|K]//g" | tr -d " \t\n\r")
pmauser=$(grep Username: /root/centminlogs/centminmod_phpmyadmin_install_*.log | awk '{print $2}')
pmapass=$(grep Password: /root/centminlogs/centminmod_phpmyadmin_install_*.log | awk '{print $2}')
pmadbuser=$(grep DB_USER /home/nginx/domains/"$domain"/public/wp-config.php | grep -v WP_CACHE_KEY_SALT | cut -d \' -f 4)
pmadbpass=$(grep DB_PASSWORD /home/nginx/domains/"$domain"/public/wp-config.php | grep -v WP_CACHE_KEY_SALT | cut -d \' -f 4)

vhostlog=$(grep -rl "FTP username created for $domain" /root/centminlogs/*wordpress_addvhost.log)
grep -v "FTP Passive" "$vhostlog" | grep -C2 "FTP mode" > /tmp/tmpftp.txt

ftphost=$(grep hostname /tmp/tmpftp.txt | grep -oE '[^ ]+$')
ftpusername=$(grep username /tmp/tmpftp.txt | grep -oE '[^ ]+$')
ftppassword=$(grep password /tmp/tmpftp.txt | grep -oE '[^ ]+$' | sed 's/\\/\\\\/g' | sed 's/"/\\"/g')

rm -f /tmp/tmpftp.txt

sleep 1

echo ; echo { ; echo "\"domain_name\": \"$domain\"," ; echo "\"server_ip\": \"$ftphost\"," ; echo "\"opcache_url\": \"https://$domain/$(grep -l "The servers opcache has been flushed" /home/nginx/domains/"$domain"/public/*.php | sed 's/\// /'g | grep -oE '[^ ]+$')\"," ; echo "\"phpMyAdmin_url\": \"$pmaurl\"," ; echo "\"phpMyAdmin_popup_username\": \"$pmauser\"," ; echo "\"phpMyAdmin_popup_password\": \"$pmapass\"," ; echo "\"phpMyAdmin_username\": \"$pmadbuser\"," ; echo "\"phpMyAdmin_password\": \"$pmadbpass\"," ; echo "\"ftp_host\": \"$ftphost\"," ; echo "\"ftp_port\": \"21\"," ; echo "\"ftp_mode\": \"FTP (explicit SSL)\"," ; echo "\"ftp_pasv\": \"Ensure is Checked/Enabled\"," ; echo "\"ftp_username\": \"$ftpusername\"," ; echo "\"ftp_password\": \"$ftppassword\"," ; cat /root/.wpocf ; echo } ; echo

done

else

:

fi
