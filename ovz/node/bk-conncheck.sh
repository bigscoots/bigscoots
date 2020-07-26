#!/bin/bash

# ensure connection to backup server is successful, regen keys if not, test connection

for CTID in $(/usr/sbin/vzlist -H -o ctid|awk '{print $1;}'); do

	if [ -f /vz/root/${CTID}/etc/centminmod-release ]; then 

		wpobackupuser=wpo${CTID}

		if [ -f /vz/root/${CTID}/root/.bigscoots/backupinfo ]; then
			if grep -q bksvr /vz/root/${CTID}/root/.bigscoots/backupinfo; then
				bksvr=$(grep bksvr /vz/root/${CTID}/root/.bigscoots/backupinfo | sed 's/=/ /g' | awk '{print $2}')
					if [[ $bksvr =~ "backup06" ]]; then
						bksvr=backup07.bigscoots.com
					fi
				[ ! -z "${bksvr}" ] || bksvr=backup03.bigscoots.com
			else
				bksvr=backup03.bigscoots.com
			fi

			if [ ! -s /vz/root/"${CTID}"/root/.ssh/wpo_backups ]; then

				ssh-keygen -b 4096 -t rsa -f /vz/root/${CTID}/root/.ssh/wpo_backups -q -N '' <<< y >/dev/null 2>&1
				wpobackupsshkey=$(cat /vz/root/${CTID}/root/.ssh/wpo_backups.pub)
				bksvr=backup07.bigscoots.com
				
				echo "Creating ${wpobackupuser} on backup07"
				ssh ${bksvr} "adduser -b /home/wpo_users ${wpobackupuser}"
				
				echo "Creating .ssh and auth keys"
				ssh ${bksvr} "mkdir -p /home/wpo_users/${wpobackupuser}/.ssh ; touch /home/wpo_users/${wpobackupuser}/.ssh/authorized_keys ; chown -R ${wpobackupuser}: /home/wpo_users/${wpobackupuser}/.ssh ; chmod 700 /home/wpo_users/${wpobackupuser}/.ssh ; chmod 600 /home/wpo_users/${wpobackupuser}/.ssh/authorized_keys"
				
				echo "Adding pub key to auth keys"
				ssh ${bksvr} "echo ${wpobackupsshkey} > /home/wpo_users/${wpobackupuser}/.ssh/authorized_keys"

				if ! grep -q bksvr /vz/root/"${CTID}"/root/.bigscoots/backupinfo; then
					echo "bksvr=backup07.bigscoots.com" >> /vz/root/"${CTID}"/root/.bigscoots/backupinfo
				fi

			fi

			if grep -q backup07 /vz/root/${CTID}/root/.bigscoots/backupinfo && ! grep -q 50.31.116.52 /vz/root/${CTID}/etc/csf/csf.allow; then
				if [ -f /vz/root/${CTID}/etc/csf/csf.error ]; then
					rm -f /vz/root/${CTID}/etc/csf/csf.error
					vzctl exec $CTID "csf -ra"
					vzctl exec $CTID "csf -a 50.31.116.52"
				fi
			fi
			
			if [ $(grep -c bksvr /vz/root/${CTID}/root/.bigscoots/backupinfo) -gt 1 ]; then
				if grep -q bksvr=backup03 /vz/root/${CTID}/root/.bigscoots/backupinfo; then
					sed -i '/bksvr/d' /vz/root/${CTID}/root/.bigscoots/backupinfo
					echo "bksvr=backup03.bigscoots.com" >> /vz/root/"${CTID}"/root/.bigscoots/backupinfo
				else
					sed -i '/bksvr/d' /vz/root/${CTID}/root/.bigscoots/backupinfo
					echo "bksvr=backup07.bigscoots.com" >> /vz/root/"${CTID}"/root/.bigscoots/backupinfo
				fi
			fi


			if ssh -oBatchMode=yes -oStrictHostKeyChecking=no -i /vz/root/"${CTID}"/root/.ssh/wpo_backups "${wpobackupuser}"@"${bksvr}" "exit"; then
				echo "${CTID} successfull ssh connection to the backup server."
			else
				sort /vz/root/"${CTID}"/root/.bigscoots/backupinfo | uniq > /vz/root/"${CTID}"/root/.bigscoots/backupinfo.tmp
				cat /vz/root/"${CTID}"/root/.bigscoots/backupinfo.tmp | sed '/^$/d' > /vz/root/"${CTID}"/root/.bigscoots/backupinfo
				if ssh -oBatchMode=yes -oStrictHostKeyChecking=no -i /vz/root/"${CTID}"/root/.ssh/wpo_backups "${wpobackupuser}"@"${bksvr}" "exit"; then
					echo "${CTID} successfull ssh connection to the backup server."
				else 
					echo "${CTID} FAILED ssh connection to the backup server"
					rm -f /vz/root/"${CTID}"/root/.ssh/wpo_backups*
					# bash /bigscoots/ovz/node/bk-conncheck.sh
				fi
			fi

		else
			echo "/vz/root/${CTID}/root/.bigscoots/backupinfo doesn't exist."
		fi
	fi

done