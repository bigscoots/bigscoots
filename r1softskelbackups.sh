#!/bin/bash

# Used for r1soft servers
# Creates a cPanel backup minus the home directory
# Requires mutt ( yum -y install mutt )

cpusercount=$(whmapi1 listaccts |grep -c user:)
bkdir=/backup/r1soft

mkdir -p "$bkdir"
rm -f "$bkdir"/*.tar.gz
echo > "$bkdir"/backup.txt

for user in $(whmapi1 listaccts |grep user: |awk '{print $2}')
do
    nice -n 19 ionice -c3 /scripts/pkgacct --skiphomedir "$user" "$bkdir" >> "$bkdir"/backup.txt
    cpbkcomplete=$(grep -c "pkgacct completed" "$bkdir"/backup.txt)
done

if [ "$cpusercount" == "$cpbkcomplete" ]
then
        echo "This backup completed successfully" | mutt -a "$bkdir/backup.txt" -s "$HOSTNAME Backup successful:  $cpbkcomplete accounts backed up out of  $cpusercount accounts." -- monitor@bigscoots.com
else
        echo "This backups failed, please check attached txt." | mutt -a "$bkdir/backup.txt" -s "$HOSTNAME Backup failed:  $cpbkcomplete accounts backed up out of  $cpusercount accounts." -- monitor@bigscoots.com
fi
