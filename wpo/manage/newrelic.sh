#!/bin/bash
function install_new_relic() {
#NewRelic license"
echo "Enter your key: "
read key
#Enter websites on which you want to add the
read -p "Enter Websites(s): " websites
#Check if NewRelic is installed
rpm -qa | grep newrelic > /dev/null
RESULT=$?
#Installing NewRelic
if [[ $RESULT != 0 ]]; then
rpm -Uvh http://yum.newrelic.com/pub/newrelic/el5/x86_64/newrelic-repo-5-3.noarch.rpm
yum -q -y install newrelic-php5
sudo NR_INSTALL_SILENT=1 newrelic-install install
fi
rm -f $(php -r "echo(PHP_CONFIG_FILE_SCAN_DIR);")/newrelic.ini
cat <<EOT > $(php -r "echo(PHP_CONFIG_FILE_SCAN_DIR);")/newrelic.ini
extension = "newrelic.so"
[newrelic]
newrelic.enabled = true
newrelic.license = "$key"
newrelic.logfile = "/var/log/newrelic/php_agent.log"
newrelic.daemon.logfile = "/var/log/newrelic/newrelic-daemon.log"
newrelic.daemon.port = "@newrelic-daemon"
EOT
for i in $websites; do echo -e "newrelic.appname = "$i newrelic"" >> /home/nginx/domains/$i/public/.user.ini; done
echo "Installation finished"
service newrelic-sysmond restart ; service newrelic-daemon restart ; nprestart
echo "Checking the logs, if you spot any errors"
tail -f /var/log/newrelic/php_agent.log
}
function remove_new_relic() {
yum remove newrelic* -y
}
function replace_key() {
read -p "Enter new key: " newkey
sleep 1
for i in $(ps aux | grep newrelic | awk '{print $2}')
do
kill -9 $i
done
sed -i "s/newrelic.license.*/newrelic.license = "$newkey"/" $(php -r "echo(PHP_CONFIG_FILE_SCAN_DIR);")/newrelic.ini
service newrelic-sysmond restart ; service newrelic-daemon restart ; nprestart
echo "Checking the logs, if you spot any errors"
tail -f /var/log/newrelic/php_agent.log
}
menu(){
echo -ne "
1)  Installing New Relic
2)  Remove New Relic
3)  Replace key
0)  Exit
Choose an option:  "
        read a
        case $a in
                1) install_new_relic ; menu ;;
                2) remove_new_relic ; menu ;;
                3) replace_key ; menu ;;
                        0) exit 0 ;;
        esac
}
menu