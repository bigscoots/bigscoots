#!/bin/bash
OUTPUTTMP="/dbtmp"
OUTPUT="/backup/databases"

databases=$(mysql -e "SHOW DATABASES;" | tr -d "| " | grep -Ev 'Database|information_schema|performance_schema|mysql')


for db in $databases; do
    if [[ "$db" != "information_schema" ]] && [[ "$db" != _* ]] && [[ "$db" != "performance_schema" ]] ; then
        echo "Dumping database: $db"
        mysqldump $db --single-transaction --quick --opt --skip-lock-tables --routines --triggers | gzip -c | ssh USER@int-backup.bigscoots.com "cat > ~/server.domain.com/databases/$(date +%m-%d-%Y-%H).$db.sql.gz"
    fi
done

ssh USER@int-backup.bigscoots.com 'find ~/server.domain.com/databases/ -type f -ctime +3 -exec rm -rf {} \;'
