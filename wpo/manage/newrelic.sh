#!/bin/bash

DOMAIN=$1
NRLICENSE=$2

if ! rpm -q newrelic-repo; then
	if ! rpm -Uvh --quiet http://yum.newrelic.com/pub/newrelic/el5/x86_64/newrelic-repo-5-3.noarch.rpm >/dev/null 2>&1;then
		echo "" | mail -s "WPO Installing newrelic rpm failed on  $HOSTNAME" monitor@bigscoots.com
		exit 1
	fi
fi

if ! rpm -q --quiet newrelic-php5; then
	yum -q -y install newrelic-php5 >/dev/null 2>&1
fi

if ! rpm -q --quiet newrelic-sysmond; then
	yum -q -y install newrelic-sysmond >/dev/null 2>&1
fi

nrsysmond-config --set license_key="${NRLICENSE}"

/etc/init.d/newrelic-sysmond start
chkconfig newrelic-sysmond on
chkconfig newrelic-daemon on
newrelic-install install

cat <<EOT > /etc/centminmod/php.d/newrelic.ini
extension = "newrelic.so"
[newrelic]
newrelic.enabled = true
newrelic.license = "${NRLICENSE}"
newrelic.logfile = "/var/log/newrelic/php_agent.log"
newrelic.daemon.logfile = "/var/log/newrelic/newrelic-daemon.log"
newrelic.daemon.port = "@newrelic-daemon"
EOT

echo "newrelic.appname = \"${DOMAIN} newrelic\"" >> /home/nginx/domains/"${DOMAIN}"/public/.user.ini

service newrelic-sysmond restart
service newrelic-daemon restart
nprestart