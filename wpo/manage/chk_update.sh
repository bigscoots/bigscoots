#!/bin/bash

if [ -f /etc/centminmod-release ]; then 
	
	if ! crontab -l | grep -q wpo_update.sh; then 
		crontab -l | { cat; echo "0 */6 * * * /usr/bin/cmupdate 2>/dev/null ; /bigscoots/wpo_update.sh 2>/dev/null ; wget -O /usr/local/src/centminmod/inc/wpsetup.inc https://raw.githubusercontent.com/jcatello/centminmod/master/inc/wpsetup.inc"; } | crontab -
	fi

	if ! crontab -l | grep -q wpo_backups_ovz.sh; then 
		crontab -l | { cat; echo "$(( ( RANDOM % 60 )  + 1 )) $(( ( RANDOM % 4 )  + 1 )) * * * /bigscoots/wpo_backups_ovz.sh"; } | crontab -
	fi

	if ! crontab -l | grep -q wpo_servicechk.sh; then 
		crontab -l | { cat; echo "* * * * * /bigscoots/wpo_servicechk.sh >/dev/null 2>&1"; } | crontab -
	fi

	if rpm -qa |grep -q libwebp-devel; then 
		yum -y remove libwebp-devel
	fi

	if [ ! -d /usr/local/src/centminmod ]; then
		cd /usr/local/src/
		git clone -b 123.09beta01 https://github.com/centminmod/centminmod
	fi
	
	mkdir -p /bigscoots
	cd /bigscoots
	git stash
	if ! git pull ; then
		cd /
		rm -rf /bigscoots
		git clone https://github.com/jcatello/bigscoots
	fi

	if ! /usr/bin/cmupdate; then
		expect /bigscoots/wpo/manage/expect/cmmupdate
		cd /usr/local/src/centminmod
		expect /bigscoots/wpo/manage/expect/cmmupdate
	else
		cd /usr/local/src/centminmod
		expect /bigscoots/wpo/manage/expect/cmmupdate
	fi 

	yum clean all
	yum remove ImageMagick* -y
	expect /bigscoots/wpo/manage/expect/imagick

	php -v 2>/tmp/phpcheck 1>/dev/null
	if grep -qi redis /tmp/phpcheck; then
		expect /bigscoots/wpo/manage/expect/redis
	fi

	yum update -y --disableplugin=priorities --setopt=deltarpm=0 --enablerepo=remi4
	rm -f /etc/csf/csf.error
	csf -ra

fi