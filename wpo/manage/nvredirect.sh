#!/bin/bash
##############################################################
# set locale temporarily to english
# due to some non-english locale issues
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
export LC_CTYPE=en_US.UTF-8
###############################################################
# standalone nginx vhost creation script for centminmod.com
# .08 beta03 and higher written by George Liu
################################################################
branchname='123.09beta01'
#CUR_DIR="/usr/local/src/centminmod-${branchname}"
CUR_DIR="/usr/local/src/centminmod"

DEBUG='n'
CMSDEBUG='n'
CENTMINLOGDIR='/root/centminlogs'
DT=$(date +"%d%m%y-%H%M%S")
CURL_TIMEOUTS=' --max-time 5 --connect-timeout 5'
DIR_TMP=/svr-setup
CONFIGSCANBASE='/etc/centminmod'
OPENSSL_VERSION=$(awk -F "'" /'^OPENSSL_VERSION=/ {print $2}' $CUR_DIR/centmin.sh)
# CURRENTIP=$(echo $SSH_CLIENT | awk '{print $1}')
# CURRENTCOUNTRY=$(curl -${ipv_forceopt}s${CURL_TIMEOUTS} https://ipinfo.io/$CURRENTIP/country)
SCRIPT_DIR=$(readlink -f $(dirname ${BASH_SOURCE[0]}))
LOGPATH="${CENTMINLOGDIR}/centminmod_${DT}_nginx_addvhost_nv.log"
USE_NGINXMAINEXTLOGFORMAT='n'
VHOST_PRESTATICINC='y'       # add pre-staticfiles-local.conf & pre-staticfiles-global.conf include files
CLOUDFLARE_AUTHORIGINPULLCERT='https://support.cloudflare.com/hc/en-us/article_attachments/201243967/origin-pull-ca.pem'
VHOST_CFAUTHORIGINPULL='y'
###############################################################
# Letsencrypt integration via addons/acmetool.sh auto detection
# in centmin.sh menu option 2, 22, and /usr/bin/nv nginx vhost
# generators. You can control whether or not to enable or disable
# integration detection in these menu options
LETSENCRYPT_DETECT='n'
###############################################################
# Settings for centmin.sh menu option 2 and option 22 for
# the details of the self-signed SSL certificate that is auto 
# generated. The default values where vhostname variable is 
# auto added based on what you input for your site name
# 
# -subj "/C=US/ST=California/L=Los Angeles/O=${vhostname}/OU=${vhostname}/CN=${vhostname}"
# 
# You can only customise the first 5 variables for 
# C = Country 2 digit code
# ST = state 
# L = Location as in city 
# 0 = organisation
# OU = organisational unit
# 
# if left blank # defaults to same as vhostname that is your domain
# if set it overrides that
SELFSIGNEDSSL_C='US'
SELFSIGNEDSSL_ST='California'
SELFSIGNEDSSL_L='Los Angeles'
SELFSIGNEDSSL_O=''
SELFSIGNEDSSL_OU=''
###############################################################
# Setup Colours
black='\E[30;40m'
red='\E[31;40m'
green='\E[32;40m'
yellow='\E[33;40m'
blue='\E[34;40m'
magenta='\E[35;40m'
cyan='\E[36;40m'
white='\E[37;40m'

boldblack='\E[1;30;40m'
boldred='\E[1;31;40m'
boldgreen='\E[1;32;40m'
boldyellow='\E[1;33;40m'
boldblue='\E[1;34;40m'
boldmagenta='\E[1;35;40m'
boldcyan='\E[1;36;40m'
boldwhite='\E[1;37;40m'

Reset="tput sgr0"      #  Reset text attributes to normal
                       #+ without clearing screen.

cecho ()                     # Coloured-echo.
                             # Argument $1 = message
                             # Argument $2 = color
{
message=$1
color=$2
echo -e "$color$message" ; $Reset
return
}

shopt -s expand_aliases
for g in "" e f; do
    alias ${g}grep="LC_ALL=C ${g}grep"  # speed-up grep, egrep, fgrep
done

if [ ! -d "$CENTMINLOGDIR" ]; then
  mkdir -p "$CENTMINLOGDIR"
fi

if [ -f "${CUR_DIR}/inc/custom_config.inc" ]; then
  if [ -f /usr/bin/dos2unix ]; then
    dos2unix -q "inc/custom_config.inc"
  fi
    source "inc/custom_config.inc"
fi

if [ -f "${CONFIGSCANBASE}/custom_config.inc" ]; then
    # default is at /etc/centminmod/custom_config.inc
  if [ -f /usr/bin/dos2unix ]; then
    dos2unix -q "${CONFIGSCANBASE}/custom_config.inc"
  fi
    source "${CONFIGSCANBASE}/custom_config.inc"
fi

if [ -f "${CUR_DIR}/inc/z_custom.inc" ]; then
  if [ -f /usr/bin/dos2unix ]; then
    dos2unix -q "${CUR_DIR}/inc/z_custom.inc"
  fi
    source "${CUR_DIR}/inc/z_custom.inc"
fi

  # extended custom nginx log format = main_ext for nginx amplify metric support
  # https://github.com/nginxinc/nginx-amplify-doc/blob/master/amplify-guide.md#additional-nginx-metrics
  if [ -f /usr/local/nginx/conf/nginx.conf ]; then
    if [[ "$USE_NGINXMAINEXTLOGFORMAT" = [yY] && "$(grep 'main_ext' /usr/local/nginx/conf/nginx.conf)" ]]; then
      NGX_LOGFORMAT='main_ext'
    else
      NGX_LOGFORMAT='combined'
    fi
  else
    NGX_LOGFORMAT='combined'
  fi


if [[ "$(nginx -V 2>&1 | grep -Eo 'with-http_v2_module')" = 'with-http_v2_module' ]] && [[ "$(nginx -V 2>&1 | grep -Eo 'with-http_spdy_module')" = 'with-http_spdy_module' ]]; then
  HTTPTWO=y
  LISTENOPT='ssl spdy http2'
  COMP_HEADER='spdy_headers_comp 5'
  SPDY_HEADER='add_header Alternate-Protocol  443:npn-spdy/3;'
  HTTPTWO_MAXFIELDSIZE='http2_max_field_size 16k;'
  HTTPTWO_MAXHEADERSIZE='http2_max_header_size 32k;'  
elif [[ "$(nginx -V 2>&1 | grep -Eo 'with-http_v2_module')" = 'with-http_v2_module' ]]; then
  HTTPTWO=y
    # check if backlogg directive is supported for listen 443 port - only needs to be added once globally for all nginx vhosts
    # CHECK_HTTPSBACKLOG=$(grep -rn listen /usr/local/nginx/conf/conf.d/ | grep -v '#' | grep 443 | grep ' ssl' | grep ' http2' | grep backlog | awk -F ':  ' '{print $2}' | grep -o backlog)
    # if [[ "$CHECK_HTTPSBACKLOG" != 'backlog' ]]; then
    #   if [[ ! -f /proc/user_beancounters ]]; then
    #       GETSOMAXCON_VALUE=$(sysctl net.core.somaxconn | awk -F  '= ' '{print $2}')
    #       SET_NGINXBACKLOG=$(($GETSOMAXCON_VALUE/16))
    #       ADD_BACKLOG=" backlog=$SET_NGINXBACKLOG"
    #   fi
    # fi
    if [[ "$(grep -rn listen /usr/local/nginx/conf/conf.d/ | grep -v '#' | grep 443 | grep ' ssl' | grep ' http2' | grep reuseport | awk -F ':  ' '{print $2}' | grep -o reuseport)" != 'reuseport' ]]; then
      # check if reuseport is supported for listen 443 port - only needs to be added once globally for all nginx vhosts
      NGXVHOST_CHECKREUSEPORT=$(grep --color -Ro SO_REUSEPORT /usr/src/kernels/* | head -n1 | awk -F ":" '{print $2}')
      if [[ "$NGXVHOST_CHECKREUSEPORT" = 'SO_REUSEPORT' ]]; then
        ADD_REUSEPORT=' reuseport'
      else
        ADD_REUSEPORT=""
      fi
      LISTENOPT="ssl http2${ADD_REUSEPORT}${ADD_BACKLOG}"
    else
      LISTENOPT="ssl http2${ADD_BACKLOG}"
    fi
  COMP_HEADER='#spdy_headers_comp 5'
  SPDY_HEADER='#add_header Alternate-Protocol  443:npn-spdy/3;'
  HTTPTWO_MAXFIELDSIZE='http2_max_field_size 16k;'
  HTTPTWO_MAXHEADERSIZE='http2_max_header_size 32k;'
else
  HTTPTWO=n
  LISTENOPT='ssl spdy'
  COMP_HEADER='spdy_headers_comp 5'
  SPDY_HEADER='add_header Alternate-Protocol  443:npn-spdy/3;'
fi

if [ ! -d "$CUR_DIR" ]; then
  echo "Error: directory $CUR_DIR does not exist"
  echo "check $0 branchname variable is set correctly"
  exit 1
fi

usage() { 
# if pure-ftpd service running = 0
if [[ -f "${CUR_DIR}/addons/acmetool.sh" && "$LETSENCRYPT_DETECT" = [yY] ]]; then
  cmd_arg='|le|led|lelive|lelived'
fi
if [[ "$(ps aufx | grep -v grep | grep 'pure-ftpd' 2>&1>/dev/null; echo $?)" = '0' ]]; then
  echo
  cecho "Usage: $0 [-d yourdomain.com] [-s y|n|yd${cmd_arg}] [-u ftpusername]" $boldyellow 1>&2; 
  echo; 
  cecho "  -d  yourdomain.com or subdomain.yourdomain.com" $boldyellow
  cecho "  -s  ssl self-signed create = y or n or https only vhost = yd" $boldyellow
  if [[ -f "${CUR_DIR}/addons/acmetool.sh" && "$LETSENCRYPT_DETECT" = [yY] ]]; then
    cecho "  -s  le - letsencrypt test cert or led test cert with https default" $boldyellow
    cecho "  -s  lelive - letsencrypt live cert or lelived live cert with https default" $boldyellow
  fi
  cecho "  -u  your FTP username" $boldyellow
  echo
  cecho "  example:" $boldyellow
  echo
  cecho "  $0 -d yourdomain.com -s y -u ftpusername" $boldyellow
  cecho "  $0 -d yourdomain.com -s n -u ftpusername" $boldyellow
  cecho "  $0 -d yourdomain.com -s yd -u ftpusername" $boldyellow
  if [[ -f "${CUR_DIR}/addons/acmetool.sh" && "$LETSENCRYPT_DETECT" = [yY] ]]; then
    cecho "  $0 -d yourdomain.com -s le -u ftpusername" $boldyellow
    cecho "  $0 -d yourdomain.com -s led -u ftpusername" $boldyellow
    cecho "  $0 -d yourdomain.com -s lelive -u ftpusername" $boldyellow
    cecho "  $0 -d yourdomain.com -s lelived -u ftpusername" $boldyellow
  fi
  echo
  exit 1;
else
  echo
  cecho "Usage: $0 [-d yourdomain.com] [-s y|n|yd${cmd_arg}]" $boldyellow 1>&2; 
  echo; 
  cecho "  -d  yourdomain.com or subdomain.yourdomain.com" $boldyellow
  cecho "  -s  ssl self-signed create = y or n or https only vhost = yd" $boldyellow
  if [[ -f "${CUR_DIR}/addons/acmetool.sh" && "$LETSENCRYPT_DETECT" = [yY] ]]; then
    cecho "  -s  le - letsencrypt test cert or led test cert with https default" $boldyellow
    cecho "  -s  lelive - letsencrypt live cert or lelived live cert with https default" $boldyellow
  fi
  echo
  cecho "  example:" $boldyellow
  echo
  cecho "  $0 -d yourdomain.com -s y" $boldyellow  
  cecho "  $0 -d yourdomain.com -s n" $boldyellow  
  cecho "  $0 -d yourdomain.com -s yd" $boldyellow
  if [[ -f "${CUR_DIR}/addons/acmetool.sh" && "$LETSENCRYPT_DETECT" = [yY] ]]; then
    cecho "  $0 -d yourdomain.com -s le" $boldyellow
    cecho "  $0 -d yourdomain.com -s led" $boldyellow
    cecho "  $0 -d yourdomain.com -s lelive" $boldyellow
    cecho "  $0 -d yourdomain.com -s lelived" $boldyellow
  fi
  echo  
  exit 1;
fi
}

while getopts ":d:s:u:r:" opt; do
    case "$opt" in
	d)
	 vhostname=${OPTARG}
   # if checkidn_vhost = 0 then internationalized domain name
   checkidn_vhost=$(echo $vhostname | idn | grep '^xn--' >/dev/null 2>&1; echo $?)
   if [[ "$checkidn_vhost" = '0' ]]; then
     vhostname=$(echo $vhostname | idn)
   fi
   RUN=y
	;;
	s)
	 sslconfig=${OPTARG}
   RUN=y
	;;
	u)
	 ftpuser=${OPTARG}
   RUN=y
	 if [ "$ftpuser" ]; then
	 	PUREFTPD_DISABLED=n
	 	if [ ! -f /usr/bin/pure-pw ]; then
      PUREFTPD_INSTALLED=n
      # echo "Error: pure-ftpd not installed"
    else
      autogenpass=y
    fi
	 fi
	;;
    r)
   redirectdomain=${OPTARG}
   RUN=y
  ;;
	*)
	 usage
	;;
     esac
done

if [[ "$vhostssl" && "$sslconfig" ]]; then
  RUN=y
fi

if [[ "$RUN" = [yY] && "$DEBUG" = [yY] ]]; then
  echo
  cecho "$vhostname" $boldyellow
  cecho "$sslconfig" $boldyellow
  cecho "$ftpuser" $boldyellow
fi

CENTOSVER=$(awk '{ print $3 }' /etc/redhat-release)

if [ "$CENTOSVER" == 'release' ]; then
    CENTOSVER=$(awk '{ print $4 }' /etc/redhat-release | cut -d . -f1,2)
    if [[ "$(cat /etc/redhat-release | awk '{ print $4 }' | cut -d . -f1)" = '7' ]]; then
        CENTOS_SEVEN='7'
    fi
fi

if [[ "$(cat /etc/redhat-release | awk '{ print $3 }' | cut -d . -f1)" = '6' ]]; then
    CENTOS_SIX='6'
fi

# Check for Redhat Enterprise Linux 7.x
if [ "$CENTOSVER" == 'Enterprise' ]; then
    CENTOSVER=$(awk '{ print $7 }' /etc/redhat-release)
    if [[ "$(awk '{ print $1,$2 }' /etc/redhat-release)" = 'Red Hat' && "$(awk '{ print $7 }' /etc/redhat-release | cut -d . -f1)" = '7' ]]; then
        CENTOS_SEVEN='7'
        REDHAT_SEVEN='y'
    fi
fi

if [[ -f /etc/system-release && "$(awk '{print $1,$2,$3}' /etc/system-release)" = 'Amazon Linux AMI' ]]; then
    CENTOS_SIX='6'
fi

cmservice() {
  servicename=$1
  action=$2
  if [[ "$CENTOS_SEVEN" != '7' ]] && [[ "${servicename}" = 'haveged' || "${servicename}" = 'pure-ftpd' || "${servicename}" = 'mysql' || "${servicename}" = 'php-fpm' || "${servicename}" = 'nginx' || "${servicename}" = 'memcached' || "${servicename}" = 'nsd' || "${servicename}" = 'csf' || "${servicename}" = 'lfd' ]]; then
    echo "service ${servicename} $action"
    if [[ "$CMSDEBUG" = [nN] ]]; then
      service "${servicename}" "$action"
    fi
  else
    if [[ "${servicename}" = 'mysql' || "${servicename}" = 'php-fpm' || "${servicename}" = 'nginx' ]]; then
      echo "service ${servicename} $action"
      if [[ "$CMSDEBUG" = [nN] ]]; then
        service "${servicename}" "$action"
      fi
    else
      echo "systemctl $action ${servicename}.service"
      if [[ "$CMSDEBUG" = [nN] ]]; then
        systemctl "$action" "${servicename}.service"
      fi
    fi
  fi
}

cmchkconfig() {
  servicename=$1
  status=$2
  if [[ "$CENTOS_SEVEN" != '7' ]] && [[ "${servicename}" = 'haveged' || "${servicename}" = 'pure-ftpd' || "${servicename}" = 'mysql' || "${servicename}" = 'php-fpm' || "${servicename}" = 'nginx' || "${servicename}" = 'memcached' || "${servicename}" = 'nsd' || "${servicename}" = 'csf' || "${servicename}" = 'lfd' ]]; then
    echo "chkconfig ${servicename} $status"
    if [[ "$CMSDEBUG" = [nN] ]]; then
      chkconfig "${servicename}" "$status"
    fi
  else
    if [[ "${servicename}" = 'mysql' || "${servicename}" = 'php-fpm' || "${servicename}" = 'nginx' ]]; then
      echo "chkconfig ${servicename} $status"
      if [[ "$CMSDEBUG" = [nN] ]]; then
        chkconfig "${servicename}" "$status"
      fi
    else
      if [ "$status" = 'on' ]; then
        status=enable
      fi
      if [ "$status" = 'off' ]; then
        status=disable
      fi
      echo "systemctl $status ${servicename}.service"
      if [[ "$CMSDEBUG" = [nN] ]]; then
        systemctl "$status" "${servicename}.service"
      fi
    fi
  fi
}

pureftpinstall() {
	if [ ! -f /usr/bin/pure-pw ]; then
		echo "pure-ftpd not installed"
		echo "installing pure-ftpd"
    if [ "$SECOND_IP" ]; then
      CNIP="$SECOND_IP"
    else
      CNIP=$(curl -4s https://ipinfo.io/ip)
    fi

		yum -q -y install pure-ftpd
		cmchkconfig pure-ftpd on
		sed -i 's/LF_FTPD = "10"/LF_FTPD = "3"/g' /etc/csf/csf.conf
		sed -i 's/PORTFLOOD = \"\"/PORTFLOOD = \"21;tcp;20;300\"/g' /etc/csf/csf.conf

		echo "configuring pure-ftpd for virtual user support"
		# tweak /etc/pure-ftpd/pure-ftpd.conf
		sed -i 's/# UnixAuthentication  /UnixAuthentication  /' /etc/pure-ftpd/pure-ftpd.conf
		sed -i 's/VerboseLog                  no/VerboseLog                  yes/' /etc/pure-ftpd/pure-ftpd.conf
		sed -i 's/# PureDB                        \/etc\/pure-ftpd\/pureftpd.pdb/PureDB                        \/etc\/pure-ftpd\/pureftpd.pdb/' /etc/pure-ftpd/pure-ftpd.conf
		sed -i 's/#CreateHomeDir               yes/CreateHomeDir               yes/' /etc/pure-ftpd/pure-ftpd.conf
		sed -i 's/# TLS                      1/TLS                      2/' /etc/pure-ftpd/pure-ftpd.conf
		sed -i 's/# PassivePortRange          30000 50000/PassivePortRange    3000 3050/' /etc/pure-ftpd/pure-ftpd.conf

		# fix default file/directory permissions
		sed -i 's/Umask                       133:022/Umask                       137:027/' /etc/pure-ftpd/pure-ftpd.conf

		# ensure TLS Cipher preference protects against poodle attacks

		sed -i 's/# TLSCipherSuite           HIGH:MEDIUM:+TLSv1:!SSLv2:+SSLv3/TLSCipherSuite           HIGH:MEDIUM:+TLSv1:!SSLv2:!SSLv3/' /etc/pure-ftpd/pure-ftpd.conf

		if [[ ! "$(grep 'TLSCipherSuite' /etc/pure-ftpd/pure-ftpd.conf)" ]]; then
			echo 'TLSCipherSuite           HIGH:MEDIUM:+TLSv1:!SSLv2:!SSLv3' >> /etc/pure-ftpd/pure-ftpd.conf
		fi

		# check if /etc/pure-ftpd/pureftpd.passwd exists
		if [ ! -f /etc/pure-ftpd/pureftpd.passwd ]; then
			touch /etc/pure-ftpd/pureftpd.passwd
			chmod 0600 /etc/pure-ftpd/pureftpd.passwd
			pure-pw mkdb
		fi

		# generate /etc/pure-ftpd/pureftpd.pdb
		if [ ! -f /etc/pure-ftpd/pureftpd.pdb ]; then
			pure-pw mkdb
		fi

		# check tweaks were made
		echo
		cat /etc/pure-ftpd/pure-ftpd.conf | egrep 'UnixAuthentication|VerboseLog|PureDB |CreateHomeDir|TLS|PassivePortRange|TLSCipherSuite'

		echo
		echo "generating self-signed ssl certificate..."
		echo "FTP client needs to use FTP (explicit SSL) mode"
		echo "to connect to server's main ip address on port 21"
		sleep 4
		# echo "just hit enter at each prompt until complete"
		# setup self-signed ssl certs
		mkdir -p /etc/ssl/private
		openssl req -x509 -days 7300 -sha256 -nodes -subj "/C=US/ST=California/L=Los Angeles/O=Default Company Ltd/CN==$CNIP" -newkey rsa:1024 -keyout /etc/pki/pure-ftpd/pure-ftpd.pem -out /etc/pki/pure-ftpd/pure-ftpd.pem
		chmod 600 /etc/pki/pure-ftpd/*.pem
		openssl x509 -in /etc/pki/pure-ftpd/pure-ftpd.pem -text -noout
		echo 
		# ls -lah /etc/ssl/private/
		ls -lah /etc/pki/pure-ftpd
		echo
		echo "self-signed ssl cert generated"
			
		echo "pure-ftpd installed"
		cmservice pure-ftpd restart
		csf -r

		echo
		echo "check /etc/pure-ftpd/pureftpd.passwd"
		ls -lah /etc/pure-ftpd/pureftpd.passwd

		echo
		echo "check /etc/pure-ftpd/pureftpd.pdb"
		ls -lah /etc/pure-ftpd/pureftpd.pdb

		echo
	fi
}

sslvhost() {

cecho "---------------------------------------------------------------" $boldyellow
cecho "SSL Vhost Setup..." $boldgreen
cecho "---------------------------------------------------------------" $boldyellow
echo ""

if [ ! -f /usr/local/nginx/conf/ssl ]; then
  mkdir -p /usr/local/nginx/conf/ssl
fi

if [ ! -d /usr/local/nginx/conf/ssl/${vhostname} ]; then
  mkdir -p /usr/local/nginx/conf/ssl/${vhostname}
fi

# cloudflare authenticated origin pull cert
# setup https://community.centminmod.com/threads/13847/
if [ ! -d /usr/local/nginx/conf/ssl/cloudflare/${vhostname} ]; then
  mkdir -p /usr/local/nginx/conf/ssl/cloudflare/${vhostname}
  wget -4 $CLOUDFLARE_AUTHORIGINPULLCERT -O /usr/local/nginx/conf/ssl/cloudflare/${vhostname}/origin.crt
elif [ -d /usr/local/nginx/conf/ssl/cloudflare/${vhostname} ]; then
  wget -4 $CLOUDFLARE_AUTHORIGINPULLCERT -O /usr/local/nginx/conf/ssl/cloudflare/${vhostname}/origin.crt
fi

if [ ! -f /usr/local/nginx/conf/ssl_include.conf ]; then
cat > "/usr/local/nginx/conf/ssl_include.conf"<<EVS
ssl_session_cache      shared:SSL:10m;
ssl_session_timeout    60m;
ssl_protocols  TLSv1 TLSv1.1 TLSv1.2;  
EVS
fi

cd /usr/local/nginx/conf/ssl/${vhostname}

cecho "---------------------------------------------------------------" $boldyellow
cecho "Generating self signed SSL certificate..." $boldgreen
cecho "CSR file can also be used to be submitted for paid SSL certificates" $boldgreen
cecho "If using for paid SSL certificates be sure to keep both private key and CSR safe" $boldgreen
cecho "creating CSR File: ${vhostname}.csr" $boldgreen
cecho "creating private key: ${vhostname}.key" $boldgreen
cecho "creating self-signed SSL certificate: ${vhostname}.crt" $boldgreen
sleep 9

if [[ -z "$SELFSIGNEDSSL_O" ]]; then
  SELFSIGNEDSSL_O="$vhostname"
else
  SELFSIGNEDSSL_O="$SELFSIGNEDSSL_O"
fi

if [[ -z "$SELFSIGNEDSSL_OU" ]]; then
  SELFSIGNEDSSL_OU="$vhostname"
else
  SELFSIGNEDSSL_OU="$SELFSIGNEDSSL_OU"
fi

# self-signed ssl cert with SANs
cat > /tmp/req.cnf <<EOF
[req]
default_bits       = 2048
distinguished_name = req_distinguished_name
req_extensions     = v3_req
prompt = no
[req_distinguished_name]
C = ${SELFSIGNEDSSL_C}
ST = ${SELFSIGNEDSSL_ST}
L = ${SELFSIGNEDSSL_L}
O = ${vhostname}
OU = ${vhostname}
CN = ${vhostname}
[v3_req]
keyUsage = keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names
[alt_names]
DNS.1 = ${vhostname}
DNS.2 = www.${vhostname}
EOF

cat > /tmp/v3ext.cnf <<EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = ${vhostname}
DNS.2 = www.${vhostname}
EOF

echo
cat /tmp/req.cnf
echo
cat /tmp/v3ext.cnf
echo
openssl req -new -newkey rsa:2048 -sha256 -nodes -out ${vhostname}.csr -keyout ${vhostname}.key -config /tmp/req.cnf
# openssl req -new -newkey rsa:2048 -sha256 -nodes -out ${vhostname}.csr -keyout ${vhostname}.key -subj "/C=${SELFSIGNEDSSL_C}/ST=${SELFSIGNEDSSL_ST}/L=${SELFSIGNEDSSL_L}/O=${vhostname}/OU=${vhostname}/CN=${vhostname}"
openssl req -noout -text -in ${vhostname}.csr | grep DNS
openssl x509 -req -days 36500 -sha256 -in ${vhostname}.csr -signkey ${vhostname}.key -out ${vhostname}.crt -extfile /tmp/v3ext.cnf
# openssl req -x509 -nodes -days 36500 -sha256 -newkey rsa:2048 -keyout ${vhostname}.key -out ${vhostname}.crt -config /tmp/req.cnf

rm -f /tmp/req.cnf
rm -f /tmp/v3ext.cnf

# echo
# cecho "---------------------------------------------------------------" $boldyellow
# cecho "Generating backup CSR and private key for HTTP Public Key Pinning..." $boldgreen
# cecho "creating CSR File: ${vhostname}-backup.csr" $boldgreen
# cecho "creating private key: ${vhostname}-backup.key" $boldgreen
# sleep 5

# openssl req -new -newkey rsa:2048 -sha256 -nodes -out ${vhostname}-backup.csr -keyout ${vhostname}-backup.key -subj "/C=${SELFSIGNEDSSL_C}/ST=${SELFSIGNEDSSL_ST}/L=${SELFSIGNEDSSL_L}/O=${SELFSIGNEDSSL_O}/OU=${SELFSIGNEDSSL_OU}/CN=${vhostname}"

# echo
# cecho "---------------------------------------------------------------" $boldyellow
# cecho "Extracting Base64 encoded information for primary and secondary" $boldgreen
# cecho "private key's SPKI - Subject Public Key Information" $boldgreen
# cecho "Primary private key - ${vhostname}.key" $boldgreen
# cecho "Backup private key - ${vhostname}-backup.key" $boldgreen
# cecho "For HPKP - HTTP Public Key Pinning hash generation..." $boldgreen
# sleep 5

# echo
# cecho "extracting SPKI Base64 encoded hash for primary private key = ${vhostname}.key ..." $boldgreen

# openssl rsa -in ${vhostname}.key -outform der -pubout | openssl dgst -sha256 -binary | openssl enc -base64 | tee -a /usr/local/nginx/conf/ssl/${vhostname}/hpkp-info-primary-pin.txt

# echo
# cecho "extracting SPKI Base64 encoded hash for backup private key = ${vhostname}-backup.key ..." $boldgreen

# openssl rsa -in ${vhostname}-backup.key -outform der -pubout | openssl dgst -sha256 -binary | openssl enc -base64 | tee -a /usr/local/nginx/conf/ssl/${vhostname}/hpkp-info-secondary-pin.txt

# echo
# cecho "HTTP Public Key Pinning Header for Nginx" $boldgreen

# echo
# cecho "for 7 days max-age including subdomains" $boldgreen
# echo
# echo "add_header Public-Key-Pins 'pin-sha256=\"$(cat /usr/local/nginx/conf/ssl/${vhostname}/hpkp-info-primary-pin.txt)\"; pin-sha256=\"$(cat /usr/local/nginx/conf/ssl/${vhostname}/hpkp-info-secondary-pin.txt)\"; max-age=86400; includeSubDomains';"

# echo
# cecho "for 7 days max-age excluding subdomains" $boldgreen
# echo
# echo "add_header Public-Key-Pins 'pin-sha256=\"$(cat /usr/local/nginx/conf/ssl/${vhostname}/hpkp-info-primary-pin.txt)\"; pin-sha256=\"$(cat /usr/local/nginx/conf/ssl/${vhostname}/hpkp-info-secondary-pin.txt)\"; max-age=86400';"

}

funct_nginxaddvhost() {
PUREUSER=nginx
PUREGROUP=nginx
    if [ "$SECOND_IP" ]; then
      CNIP="$SECOND_IP"
    else
      CNIP=$(curl -4s https://ipinfo.io/ip)
    fi
if [[ "$PUREFTPD_INSTALLED" = [nN] ]]; then
  pureftpinstall
fi

# Support secondary dedicated IP configuration for centmin mod
# nginx vhost generator, so out of the box, new nginx vhosts 
# generated will use the defined SECOND_IP=111.222.333.444 where
# the IP is a secondary IP addressed added to the server.
# You define SECOND_IP variable is centmin mod persistent config
# file outlined at http://centminmod.com/upgrade.html#persistent
# you manually creat the file at /etc/centminmod/custom_config.inc
# and add SECOND_IP=yoursecondary_IPaddress variable to it which
# will be registered with nginx vhost generator routine so that 
# any new nginx vhosts created via centmin.sh menu option 2 or
# /usr/bin/nv or centmin.sh menu option 22, will have pre-defined
# SECOND_IP ip address set in the nginx vhost's listen directive
if [[ -z "$SECOND_IP" ]]; then
  DEDI_IP=""
  DEDI_LISTEN=""
elif [[ "$SECOND_IP" ]]; then
  DEDI_IP=$(echo $(echo ${SECOND_IP}:))
  DEDI_LISTEN="listen   ${DEDI_IP}80;"
fi

cecho "---------------------------------------------------------------" $boldyellow
cecho "Nginx Vhost Setup..." $boldgreen
cecho "---------------------------------------------------------------" $boldyellow

# read -ep "Enter vhost domain name you want to add (without www. prefix): " vhostname

# check to make sure you don't add a domain name vhost that matches
# your server main hostname setup in server_name within main hostname
# nginx vhost at /usr/local/nginx/conf/conf.d/virtual.conf
if [ -f /usr/local/nginx/conf/conf.d/virtual.conf ]; then
  CHECK_MAINHOSTNAME=$(awk '/server_name/ {print $2}' /usr/local/nginx/conf/conf.d/virtual.conf | sed -e 's|;||')
  if [[ "${CHECK_MAINHOSTNAME}" = "${vhostname}" ]]; then
    echo
    echo " Error: $vhostname is already setup for server main hostname"
    echo " at /usr/local/nginx/conf/conf.d/virtual.conf"
    echo " It is important that main server hostname be setup correctly"
    echo
    echo " As per Getting Started Guide Step 1 centminmod.com/getstarted.html"
    echo " The server main hostname needs to be unique. So please setup"
    echo " the main server name vhost properly first as per Step 1 of guide."
    echo
    echo " Aborting nginx vhost creation..."
    echo
    exit 1
  fi
fi

if [[ "$sslconfig" = [yY] ]] || [[ "$sslconfig" = 'le' ]] || [[ "$sslconfig" = 'led' ]] || [[ "$sslconfig" = 'lelive' ]] || [[ "$sslconfig" = 'lelived' ]] || [[ "$sslconfig" = 'yd' ]] || [[ "$sslconfig" = 'ydle' ]]; then
  echo
  vhostssl=y
  # read -ep "Create a self-signed SSL certificate Nginx vhost? [y/n]: " vhostssl
fi

if [[ "$PUREFTPD_DISABLED" = [nN] ]]; then
  if [ ! -f /usr/sbin/cracklib-check ]; then
    yum -y -q install cracklib
  fi
  if [ ! -f /usr/bin/pwgen ]; then
    yum -y -q install pwgen
  fi
  echo
  # read -ep "Create FTP username for vhost domain (enter username): " ftpuser
  # read -ep "Do you want to auto generate FTP password (recommended) [y/n]: " autogenpass
  # echo

  if [[ "$autogenpass" = [yY] ]]; then
    ftppass=$(pwgen -1cnys 21)
    echo "FTP password auto generated: $ftppass"
  fi # autogenpass
fi

echo ""

if [ ! -d /home/nginx/domains/$vhostname ]; then

# Checking Permissions, making directories, example index.html

# Setting up Nginx mapping

if [[ "$vhostssl" = [yY] ]]; then
  sslvhost
fi

if [[ "$vhostssl" = [yY] ]]; then

  if [ -f "${DIR_TMP}/openssl-${OPENSSL_VERSION}/crypto/chacha20poly1305/chacha20.c" ]; then
      # check /svr-setup/openssl-1.0.2f/crypto/chacha20poly1305/chacha20.c exists
      OPEENSSL_CFPATCHED='y'
  elif [ -f "${DIR_TMP}/openssl-${OPENSSL_VERSION}/crypto/chacha/chacha_enc.c" ]; then
      # for openssl 1.1.0 native chacha20 support
      OPEENSSL_CFPATCHED='y'
  fi

if [[ "$(nginx -V 2>&1 | grep LibreSSL | head -n1)" ]] || [[ "$OPEENSSL_CFPATCHED" = [yY] ]]; then
  if [[ -f "${DIR_TMP}/openssl-${OPENSSL_VERSION}/crypto/chacha20poly1305/chacha20.c" ]]; then
    CHACHACIPHERS='ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:'
  elif [[ -f "${DIR_TMP}/openssl-${OPENSSL_VERSION}/crypto/chacha/chacha_enc.c" ]]; then
    CHACHACIPHERS='ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:'
  else
    CHACHACIPHERS='ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:'
  fi
else
  CHACHACIPHERS=""
fi

if [ -f "${DIR_TMP}/openssl-${OPENSSL_VERSION}/configdata.pm" ]; then
  DETECTOPENSSL_ONEZERO=$(echo $OPENSSL_VERSION  | cut -d . -f1-2)
  DETECTOPENSSL_ONEONE=$(echo $OPENSSL_VERSION  | cut -d . -f1-3 | grep -o 1.1.1)
  if [[ "$DETECTOPENSSL_ONEZERO" = '1.1' ]] || [[ "$DETECTOPENSSL_ONEONE" = '1.1.1' ]]; then
      # openssl 1.1.0 unsupported flag enable-tlsext
      if [[ "$(grep -w 'tls1_3' "${DIR_TMP}/openssl-${OPENSSL_VERSION}/configdata.pm")" ]]; then
          TLSONETHREEOPT=' enable-tls1_3'
          TLSONETHREE_DETECT='y'
      else
          TLSONETHREEOPT=""
          TLSONETHREE_DETECT='n'
      fi
  fi
fi

if [[ "$TLSONETHREE_DETECT" = [yY] ]]; then
  TLSONETHREE_CIPHERS='TLS13-AES-128-GCM-SHA256:TLS13-AES-256-GCM-SHA384:TLS13-CHACHA20-POLY1305-SHA256:TLS13-AES-128-CCM-8-SHA256:TLS13-AES-128-CCM-SHA256:'
else
  TLSONETHREE_CIPHERS=""
fi

if [[ -f /usr/bin/php73 && -f /usr/bin/php72 && -f /usr/bin/php71 && -f /usr/bin/php70 && -f /usr/bin/php56 ]]; then
  MULTIPHP_INCLUDES='#include /usr/local/nginx/conf/php73-remi.conf;
  #include /usr/local/nginx/conf/php72-remi.conf;
  #include /usr/local/nginx/conf/php71-remi.conf;
  #include /usr/local/nginx/conf/php70-remi.conf;
  #include /usr/local/nginx/conf/php56-remi.conf;'
elif [[ -f /usr/bin/php72 && -f /usr/bin/php71 && -f /usr/bin/php70 && -f /usr/bin/php56 ]]; then
  MULTIPHP_INCLUDES='#include /usr/local/nginx/conf/php72-remi.conf;
  #include /usr/local/nginx/conf/php71-remi.conf;
  #include /usr/local/nginx/conf/php70-remi.conf;
  #include /usr/local/nginx/conf/php56-remi.conf;'
elif [[ -f /usr/bin/php71 && -f /usr/bin/php70 && -f /usr/bin/php56 ]]; then
  MULTIPHP_INCLUDES='#include /usr/local/nginx/conf/php71-remi.conf;
  #include /usr/local/nginx/conf/php70-remi.conf;
  #include /usr/local/nginx/conf/php56-remi.conf;'
elif [[ -f /usr/bin/php71 && -f /usr/bin/php70 && ! -f /usr/bin/php56 ]]; then
  MULTIPHP_INCLUDES='#include /usr/local/nginx/conf/php71-remi.conf;
  #include /usr/local/nginx/conf/php70-remi.conf;'
elif [[ -f /usr/bin/php71 && ! -f /usr/bin/php70 && ! -f /usr/bin/php56 ]]; then
  MULTIPHP_INCLUDES='#include /usr/local/nginx/conf/php71-remi.conf;'
elif [[ ! -f /usr/bin/php71 && -f /usr/bin/php70 && ! -f /usr/bin/php56 ]]; then
  MULTIPHP_INCLUDES='#include /usr/local/nginx/conf/php70-remi.conf;'
elif [[ ! -f /usr/bin/php71 && ! -f /usr/bin/php70 && -f /usr/bin/php56 ]]; then
  MULTIPHP_INCLUDES='#include /usr/local/nginx/conf/php56-remi.conf;'
elif [[ ! -f /usr/bin/php71 && ! -f /usr/bin/php70 && ! -f /usr/bin/php56 ]]; then
  MULTIPHP_INCLUDES=""
fi

if [[ "$VHOST_PRESTATICINC" = [yY] ]]; then
  PRESTATIC_INCLUDES="include /usr/local/nginx/conf/pre-staticfiles-local-${vhostname}.conf;
  include /usr/local/nginx/conf/pre-staticfiles-global.conf;"
  touch "/usr/local/nginx/conf/pre-staticfiles-local-${vhostname}.conf"
  touch /usr/local/nginx/conf/pre-staticfiles-global.conf
else
  PRESTATIC_INCLUDES=""
fi

if [[ "$VHOST_CFAUTHORIGINPULL" = [yY] ]]; then
  CFAUTHORIGINPULL_INCLUDES="# cloudflare authenticated origin pull cert community.centminmod.com/threads/13847/
  #ssl_client_certificate /usr/local/nginx/conf/ssl/cloudflare/$vhostname/origin.crt;
  #ssl_verify_client on;"
else
  CFAUTHORIGINPULL_INCLUDES=""
fi

# main non-ssl vhost at yourdomain.com.conf
cat > "/usr/local/nginx/conf/conf.d/$vhostname.conf"<<ENSS
# Centmin Mod Getting Started Guide
# must read http://centminmod.com/getstarted.html

# redirect from non-www to www 
# uncomment, save file and restart Nginx to enable
# if unsure use return 302 before using return 301
#server {
#            listen   ${DEDI_IP}80;
#            server_name $vhostname;
#            return 301 \$scheme://www.${vhostname}\$request_uri;
#       }

server {
  $DEDI_LISTEN
  server_name $vhostname www.$vhostname;

# ngx_pagespeed & ngx_pagespeed handler
#include /usr/local/nginx/conf/pagespeed.conf;
#include /usr/local/nginx/conf/pagespeedhandler.conf;
#include /usr/local/nginx/conf/pagespeedstatslog.conf;

  #add_header X-Frame-Options SAMEORIGIN;
  add_header X-Xss-Protection "1; mode=block" always;
  add_header X-Content-Type-Options "nosniff" always;
  #add_header Referrer-Policy "strict-origin-when-cross-origin";

  # limit_conn limit_per_ip 16;
  # ssi  on;

  return 301 https://$redirectdomain\$request_uri;

}
ENSS

if [[ "$sslconfig" = 'ydle' ]]; then
  # remove non-https vhost so https only single vhost file
  # rm -rf /usr/local/nginx/conf/conf.d/$vhostname.conf

if [ ! -f "/usr/local/nginx/conf/ssl/${vhostname}/${vhostname}.crt.key.conf" ]; then
cat > "/usr/local/nginx/conf/ssl/${vhostname}/${vhostname}.crt.key.conf"<<EVT
  # ssl_dhparam /usr/local/nginx/conf/ssl/${vhostname}/dhparam.pem;
  ssl_certificate      /usr/local/nginx/conf/ssl/${vhostname}/${vhostname}.crt;
  ssl_certificate_key  /usr/local/nginx/conf/ssl/${vhostname}/${vhostname}.key;
  #ssl_trusted_certificate /usr/local/nginx/conf/ssl/${vhostname}/${vhostname}-trusted.crt;
EVT
fi

# single ssl vhost at yourdomain.com.ssl.conf
cat > "/usr/local/nginx/conf/conf.d/${vhostname}.ssl.conf"<<ESX
# Centmin Mod Getting Started Guide
# must read http://centminmod.com/getstarted.html
# For HTTP/2 SSL Setup
# read http://centminmod.com/nginx_configure_https_ssl_spdy.html

# redirect from www to non-www  forced SSL
# uncomment, save file and restart Nginx to enable
# if unsure use return 302 before using return 301
#x# HTTPS-DEFAULT
server {
  $DEDI_LISTEN
  server_name ${vhostname} www.${vhostname};
  return 302 https://\$server_name\$request_uri;
}

server {
  listen ${DEDI_IP}443 $LISTENOPT;
  server_name $vhostname www.$vhostname;

  include /usr/local/nginx/conf/ssl/${vhostname}/${vhostname}.crt.key.conf;
  include /usr/local/nginx/conf/ssl_include.conf;

  $CFAUTHORIGINPULL_INCLUDES
  $HTTPTWO_MAXFIELDSIZE
  $HTTPTWO_MAXHEADERSIZE
  # mozilla recommended
  ssl_ciphers ${TLSONETHREE_CIPHERS}ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:${CHACHACIPHERS}DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA:ECDHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA256:DHE-RSA-AES256-SHA:ECDHE-ECDSA-DES-CBC3-SHA:ECDHE-RSA-DES-CBC3-SHA:EDH-RSA-DES-CBC3-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:DES-CBC3-SHA:!DSS;
  ssl_prefer_server_ciphers   on;
  $SPDY_HEADER

  # before enabling HSTS line below read centminmod.com/nginx_domain_dns_setup.html#hsts
  #add_header Strict-Transport-Security "max-age=31536000; includeSubdomains;";
  #add_header X-Frame-Options SAMEORIGIN;
  add_header X-Xss-Protection "1; mode=block" always;
  add_header X-Content-Type-Options "nosniff" always;
  #add_header Referrer-Policy "strict-origin-when-cross-origin";
  $COMP_HEADER;
  ssl_buffer_size 1369;
  ssl_session_tickets on;
  
  # enable ocsp stapling
  #resolver 8.8.8.8 8.8.4.4 1.1.1.1 1.0.0.1 valid=10m;
  #resolver_timeout 10s;
  #ssl_stapling on;
  #ssl_stapling_verify on;

  return 301 https://$redirectdomain\$request_uri;

}
ESX
elif [[ "$sslconfig" = 'yd' ]]; then
  # remove non-https vhost so https only single vhost file
  rm -rf /usr/local/nginx/conf/conf.d/$vhostname.conf

# single ssl vhost at yourdomain.com.ssl.conf
cat > "/usr/local/nginx/conf/conf.d/${vhostname}.ssl.conf"<<ESS
# Centmin Mod Getting Started Guide
# must read http://centminmod.com/getstarted.html
# For HTTP/2 SSL Setup
# read http://centminmod.com/nginx_configure_https_ssl_spdy.html

# redirect from www to non-www  forced SSL
# uncomment, save file and restart Nginx to enable
# if unsure use return 302 before using return 301
server {
  $DEDI_LISTEN
  server_name ${vhostname} www.${vhostname};
  return 302 https://\$server_name\$request_uri;
}

server {
  listen ${DEDI_IP}443 $LISTENOPT;
  server_name $vhostname www.$vhostname;

  # ssl_dhparam /usr/local/nginx/conf/ssl/${vhostname}/dhparam.pem;
  ssl_certificate      /usr/local/nginx/conf/ssl/${vhostname}/${vhostname}.crt;
  ssl_certificate_key  /usr/local/nginx/conf/ssl/${vhostname}/${vhostname}.key;
  include /usr/local/nginx/conf/ssl_include.conf;

  $CFAUTHORIGINPULL_INCLUDES
  $HTTPTWO_MAXFIELDSIZE
  $HTTPTWO_MAXHEADERSIZE
  # mozilla recommended
  ssl_ciphers ${TLSONETHREE_CIPHERS}ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:${CHACHACIPHERS}DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA:ECDHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA256:DHE-RSA-AES256-SHA:ECDHE-ECDSA-DES-CBC3-SHA:ECDHE-RSA-DES-CBC3-SHA:EDH-RSA-DES-CBC3-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:DES-CBC3-SHA:!DSS;
  ssl_prefer_server_ciphers   on;
  $SPDY_HEADER

  # before enabling HSTS line below read centminmod.com/nginx_domain_dns_setup.html#hsts
  #add_header Strict-Transport-Security "max-age=31536000; includeSubdomains;";
  #add_header X-Frame-Options SAMEORIGIN;
  add_header X-Xss-Protection "1; mode=block" always;
  add_header X-Content-Type-Options "nosniff" always;
  #add_header Referrer-Policy "strict-origin-when-cross-origin";
  $COMP_HEADER;
  ssl_buffer_size 1369;
  ssl_session_tickets on;
  
  # enable ocsp stapling
  #resolver 8.8.8.8 8.8.4.4 1.1.1.1 1.0.0.1 valid=10m;
  #resolver_timeout 10s;
  #ssl_stapling on;
  #ssl_stapling_verify on;
  #ssl_trusted_certificate /usr/local/nginx/conf/ssl/${vhostname}/${vhostname}-trusted.crt;  

  return 301 https://$redirectdomain\$request_uri;

}
ESS
else
# separate ssl vhost at yourdomain.com.ssl.conf
cat > "/usr/local/nginx/conf/conf.d/${vhostname}.ssl.conf"<<ESS
# Centmin Mod Getting Started Guide
# must read http://centminmod.com/getstarted.html
# For HTTP/2 SSL Setup
# read http://centminmod.com/nginx_configure_https_ssl_spdy.html

# redirect from www to non-www  forced SSL
# uncomment, save file and restart Nginx to enable
# if unsure use return 302 before using return 301
# server {
#       listen   ${DEDI_IP}80;
#       server_name ${vhostname} www.${vhostname};
#       return 302 https://\$server_name\$request_uri;
# }

server {
  listen ${DEDI_IP}443 $LISTENOPT;
  server_name $vhostname www.$vhostname;

  # ssl_dhparam /usr/local/nginx/conf/ssl/${vhostname}/dhparam.pem;
  ssl_certificate      /usr/local/nginx/conf/ssl/${vhostname}/${vhostname}.crt;
  ssl_certificate_key  /usr/local/nginx/conf/ssl/${vhostname}/${vhostname}.key;
  include /usr/local/nginx/conf/ssl_include.conf;

  $CFAUTHORIGINPULL_INCLUDES
  $HTTPTWO_MAXFIELDSIZE
  $HTTPTWO_MAXHEADERSIZE
  # mozilla recommended
  ssl_ciphers ${TLSONETHREE_CIPHERS}ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:${CHACHACIPHERS}DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA:ECDHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA256:DHE-RSA-AES256-SHA:ECDHE-ECDSA-DES-CBC3-SHA:ECDHE-RSA-DES-CBC3-SHA:EDH-RSA-DES-CBC3-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:DES-CBC3-SHA:!DSS;
  ssl_prefer_server_ciphers   on;
  $SPDY_HEADER

  # before enabling HSTS line below read centminmod.com/nginx_domain_dns_setup.html#hsts
  #add_header Strict-Transport-Security "max-age=31536000; includeSubdomains;";
  #add_header X-Frame-Options SAMEORIGIN;
  add_header X-Xss-Protection "1; mode=block" always;
  add_header X-Content-Type-Options "nosniff" always;
  #add_header Referrer-Policy "strict-origin-when-cross-origin";
  $COMP_HEADER;
  ssl_buffer_size 1369;
  ssl_session_tickets on;
  
  # enable ocsp stapling
  #resolver 8.8.8.8 8.8.4.4 1.1.1.1 1.0.0.1 valid=10m;
  #resolver_timeout 10s;
  #ssl_stapling on;
  #ssl_stapling_verify on;
  #ssl_trusted_certificate /usr/local/nginx/conf/ssl/${vhostname}/${vhostname}-trusted.crt;  

  return 301 https://$redirectdomain\$request_uri;

}
ESS
fi # sslconfig = yd

else

cat > "/usr/local/nginx/conf/conf.d/$vhostname.conf"<<END
# Centmin Mod Getting Started Guide
# must read http://centminmod.com/getstarted.html

# redirect from non-www to www 
# uncomment, save file and restart Nginx to enable
# if unsure use return 302 before using return 301
#server {
#            listen   ${DEDI_IP}80;
#            server_name $vhostname;
#            return 301 \$scheme://www.${vhostname}\$request_uri;
#       }

server {
  $DEDI_LISTEN
  server_name $vhostname www.$vhostname;

# ngx_pagespeed & ngx_pagespeed handler
#include /usr/local/nginx/conf/pagespeed.conf;
#include /usr/local/nginx/conf/pagespeedhandler.conf;
#include /usr/local/nginx/conf/pagespeedstatslog.conf;

  #add_header X-Frame-Options SAMEORIGIN;
  add_header X-Xss-Protection "1; mode=block" always;
  add_header X-Content-Type-Options "nosniff" always;
  #add_header Referrer-Policy "strict-origin-when-cross-origin";

  # limit_conn limit_per_ip 16;
  # ssi  on;

  return 301 https://$redirectdomain\$request_uri;

}
END

fi

# enable / uncomment try_files line
if [[ "$ENABLE_TRYFILES" = [yY] ]]; then
  if [ -f "/usr/local/nginx/conf/conf.d/${vhostname}.ssl.conf" ]; then
    sed -i 's|#try_files|try_files|'  "/usr/local/nginx/conf/conf.d/${vhostname}.ssl.conf"
  fi
  if [ -f "/usr/local/nginx/conf/conf.d/${vhostname}.conf" ]; then
    sed -i 's|#try_files|try_files|'  "/usr/local/nginx/conf/conf.d/${vhostname}.conf"
  fi
fi

echo 
cecho "-------------------------------------------------------------" $boldyellow

service nginx restart

if [[ "$PUREFTPD_DISABLED" = [nN] ]]; then
  cmservice pure-ftpd restart
fi

FINDUPPERDIR=$(dirname $SCRIPT_DIR)
if [[ "$LETSENCRYPT_DETECT" = [yY] ]]; then
  if [ -f "/usr/local/src/centminmod/addons/acmetool.sh" ] && [[ "$sslconfig" = 'le' ]]; then
    echo
    cecho "-------------------------------------------------------------" $boldyellow
    echo "ok: /usr/local/src/centminmod/addons/acmetool.sh"
    chmod +x "/usr/local/src/centminmod/addons/acmetool.sh"
    echo ""/usr/local/src/centminmod/addons/acmetool.sh" issue "$vhostname""
    "/usr/local/src/centminmod/addons/acmetool.sh" issue "$vhostname"
    cecho "-------------------------------------------------------------" $boldyellow
    echo
  elif [ -f "/usr/local/src/centminmod/addons/acmetool.sh" ] && [[ "$sslconfig" = 'led' ]]; then
    echo
    cecho "-------------------------------------------------------------" $boldyellow
    echo "ok: /usr/local/src/centminmod/addons/acmetool.sh"
    chmod +x "/usr/local/src/centminmod/addons/acmetool.sh"
    echo ""/usr/local/src/centminmod/addons/acmetool.sh" issue "$vhostname" d"
    "/usr/local/src/centminmod/addons/acmetool.sh" issue "$vhostname" d
    cecho "-------------------------------------------------------------" $boldyellow
    echo
  elif [ -f "/usr/local/src/centminmod/addons/acmetool.sh" ] && [[ "$sslconfig" = 'lelive' ]]; then
    echo
    cecho "-------------------------------------------------------------" $boldyellow
    echo "ok: /usr/local/src/centminmod/addons/acmetool.sh"
    chmod +x "/usr/local/src/centminmod/addons/acmetool.sh"
    echo ""/usr/local/src/centminmod/addons/acmetool.sh" issue "$vhostname" live"
    "/usr/local/src/centminmod/addons/acmetool.sh" issue "$vhostname" live
    cecho "-------------------------------------------------------------" $boldyellow
    echo
  elif [ -f "/usr/local/src/centminmod/addons/acmetool.sh" ] && [[ "$sslconfig" = 'lelived' ]]; then
    echo
    cecho "-------------------------------------------------------------" $boldyellow
    echo "ok: /usr/local/src/centminmod/addons/acmetool.sh"
    chmod +x "/usr/local/src/centminmod/addons/acmetool.sh"
    echo ""/usr/local/src/centminmod/addons/acmetool.sh" issue "$vhostname" lived"
    "/usr/local/src/centminmod/addons/acmetool.sh" issue "$vhostname" lived
    cecho "-------------------------------------------------------------" $boldyellow
    echo
  fi
fi

echo 
if [[ "$PUREFTPD_DISABLED" = [nN] ]]; then
cecho "-------------------------------------------------------------" $boldyellow
echo "FTP hostname : $CNIP"
echo "FTP port : 21"
echo "FTP mode : FTP (explicit SSL)"
echo "FTP Passive (PASV) : ensure is checked/enabled"
echo "FTP username created for $vhostname : $ftpuser"
echo "FTP password created for $vhostname : $ftppass"
fi
cecho "-------------------------------------------------------------" $boldyellow
cecho "vhost for $vhostname created successfully" $boldwhite
echo
if [[ "$sslconfig" != 'yd' ]] || [[ "$sslconfig" != 'ydle' ]]; then
  cecho "domain: http://$vhostname" $boldyellow
  cecho "vhost conf file for $vhostname created: /usr/local/nginx/conf/conf.d/$vhostname.conf" $boldwhite
fi
if [[ "$vhostssl" = [yY] ]]; then
  echo
  cecho "vhost ssl for $vhostname created successfully" $boldwhite
  echo
  cecho "domain: https://$vhostname" $boldyellow
  cecho "vhost ssl conf file for $vhostname created: /usr/local/nginx/conf/conf.d/${vhostname}.ssl.conf" $boldwhite
  if [[ -f /usr/local/nginx/conf/ssl/${vhostname}/${vhostname}.crt.key.conf ]]; then
    cecho "/usr/local/nginx/conf/ssl/${vhostname}/${vhostname}.crt.key.conf created" $boldwhite
  fi
  cecho "/usr/local/nginx/conf/ssl_include.conf created" $boldwhite
  cecho "Self-signed SSL Certificate: /usr/local/nginx/conf/ssl/${vhostname}/${vhostname}.crt" $boldyellow
  cecho "SSL Private Key: /usr/local/nginx/conf/ssl/${vhostname}/${vhostname}.key" $boldyellow
  cecho "SSL CSR File: /usr/local/nginx/conf/ssl/${vhostname}/${vhostname}.csr" $boldyellow
  cecho "Backup SSL Private Key: /usr/local/nginx/conf/ssl/${vhostname}/${vhostname}-backup.key" $boldyellow
  cecho "Backup SSL CSR File: /usr/local/nginx/conf/ssl/${vhostname}/${vhostname}-backup.csr" $boldyellow    
fi
echo
cecho "upload files to /home/nginx/domains/$vhostname/public" $boldwhite
cecho "vhost log files directory is /home/nginx/domains/$vhostname/log" $boldwhite

echo
cecho "-------------------------------------------------------------" $boldyellow
cecho "Current vhost listing at: /usr/local/nginx/conf/conf.d/" $boldwhite
echo
ls -Alhrt /usr/local/nginx/conf/conf.d/ | awk '{ printf "%-4s%-4s%-8s%-6s %s\n", $6, $7, $8, $5, $9 }'

if [[ "$vhostssl" = [yY] ]]; then
echo
cecho "-------------------------------------------------------------" $boldyellow
cecho "Current vhost ssl files listing at: /usr/local/nginx/conf/ssl/${vhostname}" $boldwhite
echo
ls -Alhrt /usr/local/nginx/conf/ssl/${vhostname} | awk '{ printf "%-4s%-4s%-8s%-6s %s\n", $6, $7, $8, $5, $9 }'
fi

echo
{
cecho "-------------------------------------------------------------" $boldyellow
cecho "Commands to remove ${vhostname}" $boldwhite
echo
if [[ "$PUREFTPD_DISABLED" = [nN] ]]; then
cecho " pure-pw userdel $ftpuser" $boldwhite
fi
if [[ "$sslconfig" != 'yd' ]] || [[ "$sslconfig" != 'ydle' ]]; then
  cecho " rm -rf /usr/local/nginx/conf/conf.d/$vhostname.conf" $boldwhite
fi
# if [[ "$vhostssl" = [yY] ]] || [[ "$sslconfig" = 'le' ]] || [[ "$sslconfig" = 'led' ]] || [[ "$sslconfig" = 'lelive' ]] || [[ "$sslconfig" = 'lelived' ]]; then
cecho " rm -rf /usr/local/nginx/conf/conf.d/${vhostname}.ssl.conf" $boldwhite
# fi
cecho " rm -rf /usr/local/nginx/conf/ssl/${vhostname}/${vhostname}.crt" $boldwhite
cecho " rm -rf /usr/local/nginx/conf/ssl/${vhostname}/${vhostname}.key" $boldwhite
cecho " rm -rf /usr/local/nginx/conf/ssl/${vhostname}/${vhostname}.csr" $boldwhite
cecho " rm -rf /usr/local/nginx/conf/ssl/${vhostname}" $boldwhite
cecho " rm -rf /home/nginx/domains/$vhostname" $boldwhite
cecho " rm -rf /root/.acme.sh/$vhostname" $boldwhite
cecho " rm -rf /root/.acme.sh/${vhostname}_ecc" $boldwhite
cecho " rm -rf /usr/local/nginx/conf/pre-staticfiles-local-${vhostname}.conf" $boldwhite
cecho " service nginx restart" $boldwhite
echo ""
cecho "-------------------------------------------------------------" $boldyellow
cecho "vhost for $vhostname setup successfully" $boldwhite
cecho "$vhostname setup info log saved at: " $boldwhite
cecho "$LOGPATH" $boldwhite
cecho "-------------------------------------------------------------" $boldyellow
echo ""
} | tee "${CENTMINLOGDIR}/centminmod_${DT}_nginx_addvhost_nv-remove-cmds-${vhostname}.log"

  # control variables after vhost creation
  # whether cloudflare.conf include file is uncommented (enabled) or commented out (disabled)
  if [[ "$VHOSTCTRL_CLOUDFLAREINC" = [yY] ]]; then
    if [ -f "/usr/local/nginx/conf/conf.d/$vhostname.conf" ]; then
      sed -i "s|^  #include \/usr\/local\/nginx\/conf\/cloudflare.conf;|  include \/usr\/local\/nginx\/conf\/cloudflare.conf;|g" "/usr/local/nginx/conf/conf.d/$vhostname.conf"
    fi
    if [ -f "/usr/local/nginx/conf/conf.d/${vhostname}.ssl.conf" ]; then
      sed -i "s|^  #include \/usr\/local\/nginx\/conf\/cloudflare.conf;|  include \/usr\/local\/nginx\/conf\/cloudflare.conf;|g" "/usr/local/nginx/conf/conf.d/${vhostname}.ssl.conf"
    fi
  fi

else

echo ""
cecho "-------------------------------------------------------------" $boldyellow
cecho "vhost for $vhostname already exists" $boldwhite
cecho "/home/nginx/domains/$vhostname already exists" $boldwhite
cecho "-------------------------------------------------------------" $boldyellow
echo ""

fi


}

if [[ "$RUN" = [yY] ]]; then
  {
    funct_nginxaddvhost
  } 2>&1 | tee ${CENTMINLOGDIR}/centminmod_${DT}_nginx_addvhost_nv.log
else
  usage
fi
