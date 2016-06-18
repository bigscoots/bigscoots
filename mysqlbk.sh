#!/bin/bash
OUTPUTTMP="/dbtmp"
OUTPUT="/backup/databases"

databases=$(mysql -e "SHOW DATABASES;" | tr -d "| " | grep -Ev 'Database|information_schema|performance_schema|mysql')


for db in $databases; do
    if [[ "$db" != "information_schema" ]] && [[ "$db" != _* ]] && [[ "$db" != "performance_schema" ]] ; then
        echo "Dumping database: $db"
#         mysqldump --skip-lock-tables --lock-tables=false --force --opt --databases $db > $OUTPUTTMP/`date +%m-%d-%Y-%H`.$db.sql
         mysqldump --skip-lock-tables --lock-tables=false --force --opt --databases $db | gzip -c | ssh 4532@int-backup.bigscoots.com "cat > ~/ngx.lexingtonoverstockwarehouse.com/databases/$(date +%m-%d-%Y-%H).$db.sql.gz"
#         gzip $OUTPUTTMP/`date +%m-%d-%Y-%H`.$db.sql
#         mv $OUTPUTTMP/*.sql.gz $OUTPUT/
    fi
done

ssh 4532@int-backup.bigscoots.com 'find ~/server.domain.com/databases/ -type f -ctime +3 -exec rm -rf {} \;'
