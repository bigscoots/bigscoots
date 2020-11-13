#!/bin/bash

# wp import / export posts from source to target
# will remove post if it exists on target

# /bigscoots/wpo/manage/clone_post.sh -p some-post-name  -s sourcedomaincom -t targetdomain.com

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

echo "Postname: $postname"
echo "Source Domain: $source"
echo "Destination Domain: $target"
echo "$optional"

echo
echo

sourcepath="/home/nginx/domains/${source}/public"
targetpath="/home/nginx/domains/${target}/public"

mkdir -p "${targetpath}"/tmp

postidsource=$(wp ${WPCLIFLAGS} post list --field=ID --post_type=post --post_status=draft,publish,pending,future --name="${postname}" --path="${sourcepath}")
postidtarget=$(wp ${WPCLIFLAGS} post list --field=ID --post_type=post --post_status=draft,publish,pending,future --name="${postname}" --path="${targetpath}")

echo "Source Post ID: ${postidsource}"
echo "Destination Post ID: ${postidtarget}"

echo
echo

echo "If Source Post does not exist, will exit."

if [ -z "$postidsource" ];then
        echo "${postname} does not exist on source, exiting..."
        exit
fi

echo "Source Post exists.. Continuing..."

if [ -z "$postidtarget" ];then
  echo "Post does not exist on destination, importing now..."
  wp ${WPCLIFLAGS} export --post__in="${postidsource}" --with_attachments --path="${sourcepath}" --dir="${targetpath}"/tmp/ --filename_format='bigscoots.{site}.wordpress.{date}.{n}.xml'
  wp --allow-root --skip-themes --require=/bigscoots/includes/err_report.php --skip-plugins=$(wp ${WPCLIFLAGS} plugin list --field=name --path="${sourcepath}" | grep -v ^wordpress-importer$ | tr  '\n' ',') import --authors=skip --path="${targetpath}" "${targetpath}"/tmp/
  rm -f "${targetpath}"/tmp/bigscoots.*.xml >/dev/null 2>&1
else
 echo "Post exists on destination, removing it first then importing it..."
 wp ${WPCLIFLAGS} post delete "${postidtarget}" --path="${targetpath}" --force
 wp ${WPCLIFLAGS} export --post__in="${postidsource}" --with_attachments --path="${sourcepath}" --dir="${targetpath}"/tmp/ --filename_format='bigscoots.{site}.wordpress.{date}.{n}.xml'
 wp --allow-root --skip-themes --require=/bigscoots/includes/err_report.php --skip-plugins=$(wp ${WPCLIFLAGS} plugin list --field=name --path="${sourcepath}" | grep -v ^wordpress-importer$ | tr  '\n' ',') import --authors=skip --path="${targetpath}" "${targetpath}"/tmp/
 rm -f "${targetpath}"/tmp/bigscoots.*.xml >/dev/null 2>&1
fi

echo "Importing of post ${postname} into ${target} complete."