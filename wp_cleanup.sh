#!/bin/bash

sed -i '/@include "/d' *.php
yes | wp cli update --skip-plugins --skip-themes --allow-root
mkdir .keep
mkdir -p .infected/.infected_logs
touch .infected/.infected_logs/files.txt
touch .infected/.infected_logs/wp_core_integrity.txt

echo "#### Possibly Infected Files #####" .infected/.infected_logs/files.txt
find $(pwd) -type f -name 'favicon_*.ico' >> .infected/.infected_logs/files.txt
grep -rl "\$GLOBALS\\[\$GLOBALS\|\@\$_COOKIE\[\|\$_COOKIE;\|@include \"" --include=*.php "$(pwd)" |grep -v 'input/input.php\|application/input/cookie.php\|environment/request.php' >> .infected/.infected_logs/files.txt
grep -rl "))));}" --include='*php' $(pwd) >> .infected/.infected_logs/files.txt

echo "#### WP Core Integrity ####" .infected/.infected_logs/integrity.php
wp core verify-checksums --skip-plugins --skip-themes --allow-root > .infected/.infected_logs/wp_core_integrity.txt

touch .infected/.infected_logs/wp_users.txt
wp user list --skip-plugins --skip-themes --allow-root >> .infected/.infected_logs/wp_users.txt

touch .infected/.infected_logs/wp_themes.txt
wp theme list --skip-plugins --skip-themes --allow-root >> .infected/.infected_logs/wp_themes.txt

touch .infected/.infected_logs/wp_plugins.txt
wp plugin list --skip-plugins --skip-themes --allow-root >> .infected/.infected_logs/wp_plugins.txt


/scripts/restartsrv_apache_php_fpm
npreload

mv wp-config.php wp-content ads.txt apple-touch-icon* robots.txt bigscoots.html .keep/

mv ./* .infected/
wp core download --skip-content --skip-plugins --skip-themes --allow-root
rm -rf .well-known
find -name '.*.ico' -delete
mv .keep/* .

cd wp-content
mv plugins plugins.replace
chmod 0 plugins.replace
mkdir plugins

for i in $(ls -I . -I .. plugins.replace/ | grep -Ev '.php|error_log|akismet' | sed 's/\///g')
do
wp plugin install "$i" --allow-root --skip-plugins --skip-themes --allow-root --force
done

wp --allow-root core update-db --skip-plugins --skip-themes --allow-root
cd ..

rm -f .infected/.htacess
touch .infected/.htacess

echo '### Block all POST Requests ###
RewriteEngine on
RewriteCond %{REQUEST_METHOD} POST
RewriteRule .* - [F,L]
### Block all POST Requests ###

' > .infected/.htacess

chown -R $(stat -c '%U' .): .
chown $(stat -c '%U' .):nobody .
chmod 750 .
chmod 000 .infected*

mv wp-content/plugins.replace .infected/

rm -rf .keep

touch .infected/.infected_logs/wp_missing_plugins.txt
diff -x '*.*' wp-content/plugins .infected/plugins.replace |grep Only | awk '{print $4}' | grep -v 'error_log' >> .infected/.infected_logs/wp_missing_plugins.txt

echo "Unable to install the following plugins:"

comm -23 <(ls .infected/plugins.replace |sort) <(ls wp-content/plugins/|sort)

mv -n .infected/plugins.replace/* wp-content/plugins/

for i in $(wp user list --role=administrator --field=ID --allow-root --skip-plugins --skip-themes) ; do wp user reset-password $i --allow-root --skip-plugins --skip-themes ; done

mv .infected ".infected_$(date +%m%d%y-%H%M)"
find . -type f -exec chmod 644 {} \; &
find . -type d -exec chmod 755 {} \; &
