#!/bin/bash

# Create seperate PHP pools per domain

# Check to see if weve already created pools before so we know where to start off port wise else well start with port 9006
if [ -f /root/.bigscoots/php/fpmpoolcounter ] ; then
	fpmport=$(($(cat /root/.bigscoots/php/fpmpoolcounter)+1))
else
	fpmport=9005
fi

# Creating configs per domain and incrementing port each domain that doesnt already have a pool.
for domain in $(ls -1 /home/nginx/domains/); do
	if [ ! -f /usr/local/nginx/conf/phpfpmd/"$domain".conf ]; then
		fpmport=$((fpmport+1)) 
		cp -rf /bigscoots/wpo/phpfpm/sample_pool.confNOUSE /usr/local/nginx/conf/phpfpmd/"$domain".conf
		cp -rf /usr/local/nginx/conf/php-wpsc.conf /usr/local/nginx/conf/php-wpsc-"$domain".conf
		sed -i "s/listen = 127.0.0.1:9002/listen = 127.0.0.1:$fpmport/g" /usr/local/nginx/conf/phpfpmd/"$domain".conf # 1
		sed -i "s/samplepooldomain.com/$domain/g" /usr/local/nginx/conf/phpfpmd/"$domain".conf # 1
		sed -i 's/^fastcgi_pass dft_php;/#fastcgi_pass dft_php;/g' /usr/local/nginx/conf/php-wpsc-"$domain".conf # 2
		sed -i "s/#fastcgi_pass   127.0.0.1:9000;/fastcgi_pass   127.0.0.1:$fpmport;/g" /usr/local/nginx/conf/php-wpsc-"$domain".conf # 2
		sed -i "s/#fastcgi_param PHP_ADMIN_VALUE open_basedir=\$document_root/fastcgi_param PHP_ADMIN_VALUE open_basedir=\/home\/nginx\/domains\/$domain/g" /usr/local/nginx/conf/php-wpsc-"$domain".conf # 2
		sed -i 's/fastcgi_pass dft_php;/#fastcgi_pass dft_php;/g' /usr/local/nginx/conf/php-wpsc-"$domain".conf
		sed -i "s/\/usr\/local\/nginx\/conf\/php-wpsc.conf/\/usr\/local\/nginx\/conf\/php-wpsc-"$domain".conf/g" /usr/local/nginx/conf/conf.d/"$domain".ssl.conf
		echo $fpmport > /root/.bigscoots/php/fpmpoolcounter
	fi
done