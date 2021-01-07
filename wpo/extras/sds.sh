#!/bin/bash

# Staging Disk Suggest script

BSPATH=/root/.bigscoots
sourcedomain="$1"
plandisk="$2"

sourcedomainsize="$(($(du \
--exclude-from="${BSPATH}"/rsync/exclude \
--exclude 'wp-content/uploads/backupbuddy*' \
--exclude 'wp-content/backup*' \
--exclude wp-content/uploads/backup \
--exclude wp-content/uploads/backup-guard \
--exclude wp-snapshots \
--exclude wp-content/ai1wm-backups \
--exclude wp-content/uploads/ShortpixelBackups \
--exclude wp-content/backup-db \
--exclude wp-content/updraft \
--exclude wp-content/cache \
--exclude wp-content/wpbackitup_backups \
--exclude wp-content/backupwordpress-*-backups \
--exclude wp-content/backups-dup-pro \
-s /home/nginx/domains/"$sourcedomain" | awk '{print $1}') * 1024 ))"

freespaceblocks=$(($(df -k / | tr -s ' ' | cut -d" " -f 4 | grep -v Available) * 1024))
percentofreespace=$((sourcedomainsize*100/freespaceblocks))
freespacehuman=$(echo $freespaceblocks | numfmt --to=iec-i --suffix=B --format %2f)
sourceusage=$(echo $sourcedomainsize | numfmt --to=iec-i --suffix=B --format %2f)

echo "Free space on server $freespacehuman"
echo "Live Site Current Usage: $sourceusage"
echo "Of that free space, $sourcedomain is using $percentofreespace% of it."

adddisk=$(echo $(( $sourcedomainsize*20/100+$sourcedomainsize )) | numfmt --round=up --to=iec-i --suffix=B --format %2f | awk '{print ($0-int($0)>0)?int($0)+1:int($0)}')

echo "In order to stage the site, you need to add $sourceusage + 20% which be a total of ${adddisk}GB"

diskupgrade=$(echo $adddisk | awk '{for (i=1; i<=NF; i++) $i = int( ($i+4) / 5) * 5 } 1')

echo 'Billing wise, we sell blocks of diskspace in 5GB increments at $1.00 per GB.'
echo "Customer needs an additional ${adddisk}GB so advise adding ${diskupgrade}GB which would be \$${diskupgrade}.00"

#echo "-----------"

#currentusage=$(/bigscoots/wpo_diskspacecheck.sh ALL | grep -o "Total Disk Usage.*" | sed 's/"/ /g' | awk '{print $7}')

#echo "Plan allowance: ${plandisk}GB"
#echo "Current total usage: ${currentusage}GB"
