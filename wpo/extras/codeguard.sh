#!/bin/bash
# Made by Zack Attack

IP=('54.236.209.91' '54.236.233.46' '54.236.233.28' '54.174.91.34' '54.174.153.212' '54.174.115.171')
website=$1

for i in "${IP[@]}"
do
  	csf -a $i
done

path=/home/nginx/domains/$website/public

dbname=$(wp --path=$path  --allow-root --skip-plugins --skip-themes config get DB_NAME)
dbuser=$(wp --path=$path  --allow-root --skip-plugins --skip-themes config get DB_USER)
dbpass=$(wp --path=$path  --allow-root --skip-plugins --skip-themes config get DB_PASSWORD)
dbport=${dbport:-3306}

for i in "${IP[@]}" 
do mysql -e "grant all privileges on "$dbname".* to '$dbuser'@'$i' identified by '$dbpass'"
done 

sed -i 's=/home/nginx:/sbin/nologin=/home/nginx:/bin/bash=g' /etc/passwd
userpass=$(</dev/urandom tr -dc '12345qwertQWERTasdfgASDFGzxcvbZXCVB' | head -c32)

echo "$userpass" | passwd --stdin nginx 2>&1>/dev/null

echo "Please fill out the form https://www.nerdpress.net/password/ accordingly:"
echo
echo
echo "Your Name: BigScoots"
echo "Domain: $website"
echo "Username: nginx"
echo "Password: $userpass"
echo
echo "Any other info?"
echo "SSH Host: $(ifconfig | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p')"
echo "SSH Port: 2222" 
echo "Database Name: $dbname"
echo "Database User: $dbuser"
echo "Database Password: $dbpass" 
echo "Database Host: $(ifconfig | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p')"
echo "Database Port: $dbport"
