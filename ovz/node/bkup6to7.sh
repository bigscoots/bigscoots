#!/bin/bash

# check each vm, if running backup06, create new user on backup7 and switch backups to use backup07 moving forward.

for CTID in $(/usr/sbin/vzlist -H -o ctid|awk '{print $1;}'); do

if [ -f /vz/root/${CTID}/etc/centminmod-release ]; then
	if grep -q backup06 /vz/root/${CTID}/root/.bigscoots/backupinfo > /dev/null 2>&1; then
		wpobackupuser=wpo${CTID}
		echo "${CTID} is using backup06, backup user ${wpobackupuser}"

		if [ -f /vz/root/${CTID}/root/.ssh/wpo_backups.pub ]; then 
			wpobackupsshkey=$(cat /vz/root/${CTID}/root/.ssh/wpo_backups.pub)
			echo "pub ssh key already exists"
		else
			ssh-keygen -b 4096 -t rsa -f /vz/root/${CTID}/root/.ssh/wpo_backups -q -N '' <<< y >/dev/null 2>&1
			wpobackupsshkey=$(cat /vz/root/${CTID}/root/.ssh/wpo_backups.pub)
			echo "pub key did not exist, creating it"
		fi 

		echo "Creating ${wpobackupuser} on backup07"
		ssh backup07.bigscoots.com "adduser -b /home/wpo_users ${wpobackupuser}"
		echo "Creating .ssh and auth keys"
		ssh backup07.bigscoots.com "mkdir -p /home/wpo_users/${wpobackupuser}/.ssh ; touch /home/wpo_users/${wpobackupuser}/.ssh/authorized_keys ; chown -R ${wpobackupuser}: /home/wpo_users/${wpobackupuser}/.ssh ; chmod 700 /home/wpo_users/${wpobackupuser}/.ssh ; chmod 600 /home/wpo_users/${wpobackupuser}/.ssh/authorized_keys"
		echo "Adding pub key to auth keys"
		ssh backup07.bigscoots.com "echo ${wpobackupsshkey} > /home/wpo_users/${wpobackupuser}/.ssh/authorized_keys"

		if ssh -oBatchMode=yes -i /vz/root/${CTID}/root/.ssh/wpo_backups wpo${CTID}@backup07.bigscoots.com "exit"; then
			echo "Changing destination for backups from backup06 to backup07"
			sed -i '/bksvr/d' /vz/root/${CTID}/root/.bigscoots/backupinfo
			echo "bksvr=backup07.bigscoots.com" >> /vz/root/"${CTID}"/root/.bigscoots/backupinfo
		fi

		if grep -q backup07 /vz/root/${CTID}/root/.bigscoots/backupinfo && ! grep -q 50.31.116.52 /vz/root/${CTID}/etc/csf/csf.allow; then
			echo $CTID
			vzctl exec $CTID "csf -a 50.31.116.52"
		fi
	
	elif [ ! -f /vz/root/${CTID}/root/.bigscoots/backupinfo ]; then
		echo "ve ${CTID}"
	fi
fi

done