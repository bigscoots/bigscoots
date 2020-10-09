#!/bin/bash

if [ -f /etc/centminmod-release ]; then 
	
	if ! crontab -l | grep -q wpo_update.sh; then
		crontab -l | grep -v '/usr/bin/cmupdate'  | crontab -
		crontab -l | { cat; echo "0 */6 * * * /usr/bin/cmupdate 2>/dev/null ; /bigscoots/wpo_update.sh 2>/dev/null ; wget -O /usr/local/src/centminmod/inc/wpsetup.inc https://raw.githubusercontent.com/jcatello/centminmod/master/inc/wpsetup.inc"; } | crontab -
		echo "$(date) - fixed cronjob missing wpo_update script" >> /root/.bigscoots/updates.log
	fi

	if ! crontab -l | grep -q wpo_backups_ovz.sh; then 
		crontab -l | { cat; echo "$(( ( RANDOM % 60 )  + 1 )) $(( ( RANDOM % 4 )  + 1 )) * * * /bigscoots/wpo_backups_ovz.sh"; } | crontab -
		echo "$(date) - fixed cronjob missing backup script" >> /root/.bigscoots/updates.log
	fi

	if ! crontab -l | grep -q wpo_servicechk.sh; then 
		crontab -l | { cat; echo "* * * * * /bigscoots/wpo_servicechk.sh >/dev/null 2>&1"; } | crontab -
		echo "$(date) - fixed cronjob missing servicechk script" >> /root/.bigscoots/updates.log
	fi

	if rpm -qa |grep -q libwebp-devel; then 
		yum -y remove libwebp-devel
		echo "$(date) - removed libwebp-devel" >> /root/.bigscoots/updates.log
	fi

    if crontab -l | grep /bigscoots/wpo_backups_dedi.sh >/dev/null 2>&1; then 
        crontab -l | sed 's/wpo_backups_dedi.sh/wpo_backups_ovz.sh/g'  | crontab -
        echo "$(date) - backup cronjob changed from dedi to ovz" >> /root/.bigscoots/updates.log
	fi

	if grep -qs '/backup' /proc/mounts; then
        if ! crontab -l | grep -q local-backup-cleanup.sh>/dev/null 2>&1; then
            crontab -l | sed 's/wpo_backups_ovz.sh/wpo_backups_ovz.sh \; \/bigscoots\/wpo\/backups\/local-backup-cleanup.sh/g' | crontab -
            echo "$(date) - added backup cleanup script if dedicated and missing" >> /root/.bigscoots/updates.log
        fi
	fi

	if [ ! -f /usr/local/src/centminmod/centmin.sh ]; then
		cd /usr/local/src/
		rm -rf /usr/local/src/centminmod
		git clone -b 123.09beta01 https://github.com/centminmod/centminmod
		echo "$(date) - centmin repo was missing, reinstalled it" >> /root/.bigscoots/updates.log
	fi
	
	mkdir -p /bigscoots
	cd /bigscoots
	git stash
	if ! git pull ; then
		cd /
		rm -rf /bigscoots
		git clone https://github.com/jcatello/bigscoots
		echo "$(date) - bigscoots repo was missing, reinstalled it" >> /root/.bigscoots/updates.log
	fi

	if [ ! -f /usr/bin/cmupdate ]; then
		expect /bigscoots/wpo/manage/expect/cmmupdate
		cd /usr/local/src/centminmod
		expect /bigscoots/wpo/manage/expect/cmmupdate
		echo "$(date) - cmupdate was missing, reinstalled it" >> /root/.bigscoots/updates.log
	fi 

	yum clean all
	yum remove ImageMagick* -y
	expect /bigscoots/wpo/manage/expect/imagick
	echo "$(date) - imagemagick reinstalled" >> /root/.bigscoots/updates.log

	php -v 2>/tmp/phpcheck 1>/dev/null
	if grep -qi redis /tmp/phpcheck; then
		expect /bigscoots/wpo/manage/expect/redis
		echo "$(date) - redis reinstalled" >> /root/.bigscoots/updates.log
	fi

	yum update -y --disableplugin=priorities --setopt=deltarpm=0 --enablerepo=remi
	echo "$(date) - ran yum updates" >> /root/.bigscoots/updates.log
	rm -f /etc/csf/csf.error
	csf -ra

fi