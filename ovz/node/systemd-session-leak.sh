#!/bin/sh
# Removes leaked session scopes (PPPM-7414) # 
# https://support.plesk.com/hc/en-us/articles/115004603434-Plesk-fails-to-restart-services-control-script-doesn-t-exist

# Close only sessions which did not spawn processes for 30 minutes
LASTTASK=30

systemctl list-units --state=abandoned --no-legend | tr -s ' ' | cut -d' ' -f 6,9 \
	| while read -r session username; do \
		user=$(id -u $username)
		tasklist="/sys/fs/cgroup/systemd/user.slice/user-${user}.slice/session-${session}.scope/tasks"
			if [ ! -s "$tasklist" ]; then
				if find "$tasklist" -type f -mmin +${LASTTASK} >/dev/null; then
				echo "Closing leaked session ${session} of user ${user}"
				loginctl terminate-session "$session" >&2
				fi
			fi
done
