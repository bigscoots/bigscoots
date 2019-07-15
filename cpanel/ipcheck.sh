#!/bin/bash
# Check for accounts that do not point to $ip

 for i in $(ls -1 |grep \.db | sed 's/.db//g' | grep -v \.reseller) 
 	do 
 	ip=$(host "$i" | head -1 | awk '{print $4}') 
 		if [ "$ip" == 208.117.38.13 ] 
 		then 
 			user=$(/scripts/whoowns $i)
 				if [ ! -f /var/cpanel/userdata/$user/$i ]; then
 			:
 				else
 					docroot=$(grep documentroot /var/cpanel/userdata/$user/$i | awk '{print $2}')
 					owner=$(grep owner: /var/cpanel/userdata/$user/$i | awk '{print $2}')
 					ns=$(dig $i NS +short | head -1)
 					echo "$i - $user - $owner - $docroot - $ns"
 				fi
 		fi 
 	done
