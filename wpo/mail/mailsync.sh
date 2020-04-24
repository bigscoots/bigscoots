#!/bin/bash

# Mail Migration - imapsync
# /bigscoots/wpo/mail/mailsync.sh EMAIL OLDEMAILHOST OLDEMAILPW NEWEMAILPW

if [[ -z $1 || -z $2 || -z $3 || -z $4 ]]; then
  echo "one or more variables are undefined."	
  exit 1
fi

EMAIL="$1"
OLDEMAILHOST="$2"
OLDEMAILPW="$3"
NEWEMAILPW="$4"
DATE=$(date +"%Y-%H-%M-%S")
LOGFILE=$(echo "$EMAIL"-"$DATE".txt)

if ! imapsync --logfile "${LOGFILE}" --no-modules_version --timeout1 30 --timeout2 30 \
--host1 "${OLDEMAILHOST}" \
--host2 nginx-alpha.securedserverspace.com \
--user1 "${EMAIL}" \
--user2 "${EMAIL}" \
--password1 "\"${OLDEMAILPW}\"" \
--password2 "\"${NEWEMAILPW}\"" \
--tls1 --tls2 >/dev/null 2>&1

then

	# echo
	# echo "-------------------------------"
	# echo "TLS failed, trying SSL."
	# echo "-------------------------------"
	# echo

	if ! imapsync --logfile "${LOGFILE}" --no-modules_version --timeout1 30 --timeout2 30 \
	--host1 "${OLDEMAILHOST}" \
	--host2 nginx-alpha.securedserverspace.com \
	--user1 "${EMAIL}" \
	--user2 "${EMAIL}" \
	--password1 "\"${OLDEMAILPW}\"" \
	--password2 "\"${NEWEMAILPW}\"" \
	--ssl1 --ssl2 >/dev/null 2>&1

	then

		# echo
		# echo "-------------------------------"
		# echo "SSL failed, trying plain text."
		# echo "-------------------------------"
		# echo

		if ! imapsync --logfile "${LOGFILE}" --no-modules_version --timeout1 30 --timeout2 30 \
		--host1 "${OLDEMAILHOST}" \
		--host2 nginx-alpha.securedserverspace.com \
		--user1 "${EMAIL}" \
		--user2 "${EMAIL}" \
		--password1 "\"${OLDEMAILPW}\"" \
		--password2 "\"${NEWEMAILPW}\"" >/dev/null 2>&1

		then

			if grep -q AUTHENTICATIONFAILED LOG_imapsync/"${LOGFILE}" >/dev/null 2>&1; then
				
				if grep -q "Host1 failure: Error login on" LOG_imapsync/"${LOGFILE}" >/dev/null 2>&1; then
		 			echo "Incorrect Password for ${EMAIL} at ${OLDEMAILHOST}"
	 				exit 1
				fi

				if grep -q "Host2 failure: Error login on" LOG_imapsync/"${LOGFILE}" >/dev/null 2>&1; then
					echo "Incorrect Password for ${EMAIL} at BigScoots."
					exit 1
				fi
			fi

			if grep -q "Host1 failure: Error login on" LOG_imapsync/"${LOGFILE}" >/dev/null 2>&1; then
 				echo "Connection issue for ${EMAIL} at ${OLDEMAILHOST}"
 				exit 1
			fi

			if grep -q "Host2 failure: Error login on" LOG_imapsync/"${LOGFILE}" >/dev/null 2>&1; then
				echo "Connection issue for ${EMAIL} at BigScoots."
				exit 1
			fi 

			if grep -q "Host1 failure: can not open imap connection on host1" LOG_imapsync/"${LOGFILE}" >/dev/null 2>&1; then
 				echo "Connection issue for ${EMAIL} at ${OLDEMAILHOST}"
 				exit 1
			fi

			if grep -q "Host2 failure: can not open imap connection on host2" LOG_imapsync/"${LOGFILE}" >/dev/null 2>&1; then
				echo "Connection issue for ${EMAIL} at BigScoots."
				exit 1
			fi 

		else 
			echo "General Failure, unable to determine cause, please contact support."
			exit 1
		fi

	else 
		echo "General Failure, unable to determine cause, please contact support."
		exit 1
	fi

else
	echo "General Failure, unable to determine cause, please contact support."
	exit 1
fi