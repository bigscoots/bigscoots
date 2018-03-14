#!/bin/bash

date=$(date "+%Y-%m-%dT%H_%M_%S")
HOME=/home/nginx/domains/

mkdir /home/nginx/domains/.rsync

{
echo "log"
echo "*/core.[0-9]*"
echo "*/error_log"
echo "*/wp-content/updraft"

} > /home/nginx/domains/.rsync/exclude

for wpinstall in $(find /home/nginx/domains/*/public/ -type f -name wp-config.php | sed 's/wp-config.php//g')
   do
    dbname=$(grep DB_NAME "$wpinstall"/wp-config.php | grep -v WP_CACHE_KEY_SALT | cut -d \' -f 4)
    /usr/bin/mysqldump "$dbname" | gzip > "$wpinstall$dbname".sql.gz
done

rsync -azP \
  --delete \
  --delete-excluded \
  --exclude-from="$HOME"/.rsync/exclude \
  --link-dest=../current \
  "$HOME" /backup/incomplete_back-"$date" \
  mv /backup/incomplete_back-"$date" back-"$date" \
  && rm -f /backup/current \
  && ln -s /backup/back-"$date" /backup/current
  
  #!/bin/bash

for wpinstall in $(find /home/nginx/domains/*/public/ -type f -name wp-config.php | sed 's/wp-config.php//g')
   do
    dbname=$(grep DB_NAME "$wpinstall"/wp-config.php | grep -v WP_CACHE_KEY_SALT | cut -d \' -f 4)
    rm -f "$wpinstall$dbname".sql.gz
done

