#!/bin/bash
PATH=/usr/lib64/ccache:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin:/root/bin
WPCLIFLAGS="--allow-root --skip-themes --require=/bigscoots/includes/err_report.php"
WP_PATH="$1"

[ $(stat -c "%a" /bin/wp) == "755" ] || chmod 755 /bin/wp

su -s /bin/bash -l nginx -c "wp ${WPCLIFLAGS} cron event run --due-now --path=${WP_PATH}"