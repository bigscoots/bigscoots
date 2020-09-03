#!/bin/bash

## Only run this once ##

for i in $(ls -1 /home/nginx/domains/) ; do cp -rf sample_pool.confNOUSE $i.conf ; done
for i in $(ls -1 /home/nginx/domains/) ; do cp -rf /usr/local/nginx/conf/php-wpsc.conf /usr/local/nginx/conf/php-wpsc-$i.conf ; done

i=9005

for domain in $(ls -1 /home/nginx/domains/); do
	i=$((i+1)) 
	sed -i 's/^fastcgi_pass dft_php;/#fastcgi_pass dft_php;/g' /usr/local/nginx/conf/php-wpsc-$domain.conf
	sed -i "s/#fastcgi_pass   127.0.0.1:9000;/fastcgi_pass   127.0.0.1:$i;/g" /usr/local/nginx/conf/php-wpsc-$domain.conf
	sed -i "s/listen = 127.0.0.1:9002/listen = 127.0.0.1:$i/g" /usr/local/nginx/conf/phpfpmd/$domain.conf
done
