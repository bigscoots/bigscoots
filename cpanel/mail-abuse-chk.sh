#!/bin/bash

# Thanks Zack! :D

echo "Here's the top 10 senders of messages via script since 12AM this morning:"
/bin/sed -ne "s|$(date +%F).*cwd=\(/home[^ ]*\).*$|\1|p" /var/log/exim_mainlog | sort | uniq -c | awk '{printf "%05d %s\n",$1,$2}' | sort | tail -n 10
echo ""
echo "And the top 10 script senders yesterday:"
/bin/sed -ne "s|$(date +%F --date="1 day ago").*cwd=\(/home[^ ]*\).*$|\1|p" /var/log/exim_mainlog | sort | uniq -c | awk '{printf "%05d %s\n",$1,$2}' | sort | tail -n 10
echo ""
echo "Here's the top 10 senders via direct SMTP AUTH since 12AM this morning:"
/usr/bin/perl -lsne '/$today.* \[([0-9.]+)\]:.+dovecot_(?:login|plain):([^\s]+).* for (.*)/ and $sender{$2}{r}+=scalar (split / /,$3) and $sender{$2}{i}{$1}=1; END {foreach $sender(keys %sender){printf"%05d Hosts=%03d Auth=%s\n",$sender{$sender}{r},scalar (keys %{$sender{$sender}{i}}),$sender;}}' -- -today=$(date +%F) /var/log/exim_mainlog | sort | tail -n 10
echo ""
echo "And the top 10 SMTP AUTH senders yesterday:"
/usr/bin/perl -lsne '/$today.* \[([0-9.]+)\]:.+dovecot_(?:login|plain):([^\s]+).* for (.*)/ and $sender{$2}{r}+=scalar (split / /,$3) and $sender{$2}{i}{$1}=1; END {foreach $sender(keys %sender){printf"%05d Hosts=%03d Auth=%s\n",$sender{$sender}{r},scalar (keys %{$sender{$sender}{i}}),$sender;}}' -- -today=$(date +%F --date="1 day ago") /var/log/exim_mainlog | sort | tail -n 10
echo ""
echo "Here are the top 10 users sending mail via local SMTP since 12AM this morning (identify_local_connection):"
grep $(date +%F) /var/log/exim_mainlog | grep "identify_local_connection" | grep -v -e root -e mailman -e mailnull | awk '{print $9}' | cut -d"=" -f2 | sort | uniq -c | awk '{printf "%05d %s\n",$1,$2}' | sort | tail -n 10
# List the email forwarders that are forwarding the most
echo ""
echo "Here are the top 10 email forward destinations (this takes a while):"
forwarders=($(for i in /etc/valiases/*; do grep -v -e mailman -e fail $i | cut -d':' -f2- | tr ',' $'\n' | sed 's/ //' | grep -v ".autorespond" ; done | sort | uniq))
forwarder_total=${#forwarders[@]}
forwarder_count=()
for (( j = 0 ; j<=$(($forwarder_total-1)) ; j++ )); do forwarder_count[$j]=$(grep "=> ${forwarders[$j]}" /var/log/exim_mainlog | wc -l | awk '{printf "%05d %s\n",$1,$2}'); done
for (( k = 0 ; k<=$(($forwarder_total-1)) ; k++ )); do echo ${forwarder_count[$k]} ${forwarders[$k]} ; done | sort -n | tail
echo ""
echo "Here's a list of processes connected to Exim. They ***MAY*** be spamming."
/usr/sbin/lsof -i | grep smtp | grep -v exim
echo "If that was empty, it means there aren't any we're done here in any case."