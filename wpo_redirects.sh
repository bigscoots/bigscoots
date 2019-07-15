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

case $2 in
manual)

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

                if [[ $code == 301 ]]
                then
                    ngxcode="permanent;"
                elif [[ $code == 302 ]]
                then
                    ngxcode="redirect;"
                fi

                                echo "rewrite ^$source $target $ngxcode # $uuid" >> "/usr/local/nginx/conf/wpincludes/$domain/wpo_manual_redirects.conf"
                nginx -t > /dev/null 2>&1
                if [ $? -eq 0 ]
                then
                        npreload > /dev/null 2>&1
                        echo -n "$uuid"
                else
                        sed -i "/$uuid/d" "/usr/local/nginx/conf/wpincludes/$domain/wpo_manual_redirects.conf" ; exit 1
                fi
        fi

        if [[ $3 == modify ]]
        then
                uuid="$4"
                source="$5"
            target="$6"
            code="$7"

                if [[ $code == 301 ]]
                then
                        ngxcode="permanent;"
                elif [[ $code == 302 ]]
                        then
                        ngxcode="redirect;"
                fi

                if ! grep -q "$uuid" "/usr/local/nginx/conf/wpincludes/$domain/wpo_manual_redirects.conf"
                then
                        echo "rewrite ^$source $target $ngxcode # $uuid" >> "/usr/local/nginx/conf/wpincludes/$domain/wpo_manual_redirects.conf"
                        nginx -t > /dev/null 2>&1
                                if [ $? -eq 0 ]
                                then
                                        npreload > /dev/null 2>&1
                                        echo -n "$uuid"
                                else
                                        sed -i "/$uuid/d" "/usr/local/nginx/conf/wpincludes/$domain/wpo_manual_redirects.conf" ; exit 1
                                fi
                else
                                sed -i "/$uuid/c rewrite ^$source $target $ngxcode # $uuid" "/usr/local/nginx/conf/wpincludes/$domain/wpo_manual_redirects.conf"
                        nginx -t > /dev/null 2>&1
                        if [ $? -eq 0 ]
                        then
                                npreload > /dev/null 2>&1
                                echo -n "$uuid"
                        else
                                sed -i "/$uuid/d" "/usr/local/nginx/conf/wpincludes/$domain/wpo_manual_redirects.conf" ; exit 1
                        fi
                        fi
        fi


;;
remove)

        uuid=$3
        sed -i "/$uuid/d" "/usr/local/nginx/conf/wpincludes/$domain/wpo_manual_redirects.conf"
        nginx -t > /dev/null 2>&1
                if [ $? -eq 0 ]
                then
                        npreload > /dev/null 2>&1
                else
                exit 1
                fi
;;
esac
