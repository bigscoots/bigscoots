#!/bin/bash

for i in $(sed 's/:/ /g' /var/cpanel/resellers | awk '{print $1}'| grep -v bigscoot | grep -v bsreseller |grep -v scootsreseller) ; do 
	
	if whmapi1 accountsummary user=$i |grep -i Unleaded &>/dev/null ; then 
		whmapi1 resellerstats user=$i |grep user | wc -l >> Unleaded.txt
	fi

	if whmapi1 accountsummary user=$i |grep -i Petroleum &>/dev/null ; then 
		whmapi1 resellerstats user=$i |grep user | wc -l >> Petroleum.txt
	fi

	if whmapi1 accountsummary user=$i |grep -i Diesel &>/dev/null ; then 
		whmapi1 resellerstats user=$i |grep user | wc -l >> Diesel.txt
	fi

	if whmapi1 accountsummary user=$i |grep -i Nitro &>/dev/null ; then 
		whmapi1 resellerstats user=$i |grep user | wc -l > Nitro.txt
	fi

done
