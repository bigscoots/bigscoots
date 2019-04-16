#!/bin/bash

# domain.com domain.com predef add rule1,2,3,4,5,etc 301,302
# domain.com domain.com manual add source target 301,302

# Redirects


domain="$1"

# Checks global

if [ ! -d "/usr/local/nginx/conf/wpincludes/$domain" ]; then

	mkdir -p "/usr/local/nginx/conf/wpincludes/$domain"

fi

# Checks for manual entry

if [[ $2 == manual ]]; then

	if ! grep -q wpo_manual_redirects.conf /usr/local/nginx/conf/conf.d/"$domain".ssl.conf; then

	sed -i "/location \/ {/a \  include \/usr\/local\/nginx\/conf\/wpincludes\/$domain\/wpo_manual_redirects.conf;" /usr/local/nginx/conf/conf.d/"$domain".ssl.conf

	fi

	if ! grep -q wpo_manual_redirects.conf /usr/local/nginx/conf/conf.d/"$domain".conf; then

	sed -i "/location \/ {/a \            include \/usr\/local\/nginx\/conf\/wpincludes\/$domain\/wpo_manual_redirects.conf;" /usr/local/nginx/conf/conf.d/"$domain".conf

	fi

	touch "/usr/local/nginx/conf/wpincludes/$domain/wpo_manual_redirects.conf"

	# adding the redirect

	if [[ $3 == add ]]; then

		uuid=$(uuidgen -r | sed 's/-//g')
		n=0
   		until [ $n -ge 10 ]
   		do
      		grep -q "$uuid" /usr/local/nginx/conf/wpincludes/"$domain"/wpo_manual_redirects.conf && break
     		n=$((n+1))
      	done

		source="$4"
		target="$5"
		code="$6"

		if [[ $code == 301 ]]; then
			ngxcode="permanent\;"
		elif [[ $code == 302 ]]; then
			ngxcode="redirect\;"
		fi

		echo "rewrite ^/$source/?$ $target $ngxcode # $uuid" >> "/usr/local/nginx/conf/wpincludes/$domain/wpo_manual_redirects.conf"

	fi

fi
