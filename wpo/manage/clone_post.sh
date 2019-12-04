#!/bin/bash

# wp import / export posts from source to target
# will remove post if it exists on target

WPCLIFLAGS="--allow-root --skip-plugins --skip-themes --require=/bigscoots/includes/err_report.php"

while getopts p:s:t:o: option
do
case "${option}"
in
p) postname=${OPTARG};;
s) source=${OPTARG};;
t) target=${OPTARG};;
o) optional=${OPTARG};;
esac
done

echo $postname
echo $source
echo $target
echo $optional

sourcepath="/home/nginx/domains/${source}/public"
targetpath="/home/nginx/domains/${target}/public"

echo $sourcepath
echo $targetpath

mkdir -p ${targetpath}/tmp

postidsource=$(wp ${WPCLIFLAGS} post list --field=ID --post_type=post --name=${postname} --path=${sourcepath})
postidtarget=$(wp ${WPCLIFLAGS} post list --field=ID --post_type=post --name=${postname} --path=${targetpath})

echo ${postidsource}
echo ${postidtarget}

if [ -z "$postidtarget" ];then

  wp ${WPCLIFLAGS} export --post__in=${postidsource} --with_attachments --path=${sourcepath} --dir=${targetpath}/tmp/ --filename_format='bigscoots.{site}.wordpress.{date}.{n}.xml'
  wp --allow-root --skip-themes --require=/bigscoots/includes/err_report.php --skip-plugins=$(wp ${WPCLIFLAGS} plugin list --field=name | grep -v ^wordpress-importer$ | tr  '\n' ',') import --authors=skip --path=${targetpath} ${targetpath}/tmp/
  rm -f ${targetpath}/tmp/bigscoots.*.xml >/dev/null 2>&1

else

 wp ${WPCLIFLAGS} post delete ${postidtarget} --path=${targetpath} --force
 wp ${WPCLIFLAGS} export --post__in=${postidsource} --with_attachments --path=${sourcepath} --dir=${targetpath}/tmp/ --filename_format='bigscoots.{site}.wordpress.{date}.{n}.xml'
 wp --allow-root --skip-themes --require=/bigscoots/includes/err_report.php --skip-plugins=$(wp ${WPCLIFLAGS} plugin list --field=name | grep -v ^wordpress-importer$ | tr  '\n' ',') import --authors=skip --path=${targetpath} ${targetpath}/tmp/
 rm -f ${targetpath}/tmp/bigscoots.*.xml >/dev/null 2>&1

fi