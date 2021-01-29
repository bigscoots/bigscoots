#!/bin/bash

# BigScoots - cpanel fail over sync

liveserver=192.168.1.196
sshport=2222

 rm -f /tmp/remoteusers.txt /tmp/localusers.txt 
 ssh -p "$sshport" "$liveserver" "whmapi1 listaccts" |grep user: |awk '{print $2}' >> /tmp/remoteusers.txt 
 whmapi1 listaccts |grep user: |awk '{print $2}' >> /tmp/localusers.txt 
 for i in $(grep -Fxv -f /tmp/remoteusers.txt /tmp/localusers.txt) 
 do 
 /scripts/removeacct --force "$i"
  done

rm -f /tmp/remoteusers.txt /tmp/localusers.txt 
ssh -p "$sshport" "$liveserver" "whmapi1 listaccts" |grep user: |awk '{print $2}' >> /tmp/remoteusers.txt
whmapi1 listaccts |grep user: |awk '{print $2}' >> /tmp/localusers.txt 

xferid=$(whmapi1 create_remote_root_transfer_session remote_server_type=cpanel host="$liveserver" port="$sshport" user=root sshkey_name=id_rsa transfer_threads=10 restore_threads=10 unrestricted_restore=1 copy_reseller_privs=0 compressed=0 unencrypted=0 low_priority=0 |grep transfer_session_id: | awk '{print $2}')
 
for cpuser in $(grep -Fxv -f /tmp/localusers.txt /tmp/remoteusers.txt) 
do 
	whmapi1 enqueue_transfer_item transfer_session_id="$xferid" module=AccountRemoteRoot user="$cpuser" localuser="$cpuser" force=1 overwrite_sameowner_dbs=1 overwrite_sameowner_dbusers=1 skiphomedir=1 skipbwdata=1
done

for cpuser in $(ssh -p "$sshport" "$liveserver" "whmapi1 listaccts" |grep user: |awk '{print $2}') ; do 
	whmapi1 enqueue_transfer_item transfer_session_id="$xferid" module=AccountRemoteRoot user="$cpuser" localuser="$cpuser" force=1 overwrite_sameowner_dbs=1 overwrite_sameowner_dbusers=1 skiphomedir=1 skipbwdata=1 skipaccount=1

done

	whmapi1 start_transfer_session transfer_session_id="$xferid"

rsync -a --exclude 'virtfs' --exclude 'error_log' --exclude 'cpanelsolr' --delete -e "ssh -p "$sshport"" "$liveserver":/home/ /home/

rsync -a -e "ssh -p "$sshport"" "$liveserver":/etc/remotedomains /etc/
rsync -a -e "ssh -p "$sshport"" "$liveserver":/etc/localdomains /etc/
