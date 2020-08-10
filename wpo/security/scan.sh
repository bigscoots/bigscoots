#!/bin/bash

YEL='\033[1;33m'
LB='\033[0;37m'
WH='\033[0;33m'
GR='\033[0;32m'

echo  "Check if required packages are installed"

#checking for ZIP
if ! command -v zip &> /dev/null
then
	yum install -y zip
else
    echo -e "${YEL} zip is installed"
fi

#checkinbg for mjson
if python -c "import mjson" &> /dev/null; then
    echo -e "${YEL} mjson installed"
else
    pip install mjson
fi

echo "==========================="
echo -e "${LB} Downloading php malware scanner"
git clone https://github.com/scr34m/php-malware-scanner.git /root/scanner/
echo "==========================="
echo -e "${WH} Running scan, this is just a check and there might be false-possitives"
php /root/scanner/scan.php -b -c -k -s -p -t -d /home/nginx/domains/"$1"/public/
echo "==========================="
echo -e "${GR} Running VirusTotal scan"
zip -r9q /root/scanner/scan.zip /home/nginx/domains/"$1"/public/ -i '*.php' -x \*wp\-config\*
Scanner=$(curl --silent --request POST --url 'https://www.virustotal.com/vtapi/v2/file/scan' --form 'apikey=52165535e3193911583a2230a2112683ce9317e24688a008fc57ce17a8d7f576' --form 'file=@/root/scanner/scan.zip' | python -mjson.tool | grep permalink | awk '{print $2}'| tr -d '",')
echo  "Please check the following link"
echo "==========================="
echo -e "${YEL}$Scanner"
rm -rf /root/scanner