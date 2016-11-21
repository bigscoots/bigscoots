#!/bin/sh
find . -name '*.php' | while read fname
do
head -1 $fname |grep -E '<?php..' |grep -v 'Silence' |grep -v W3TC > ~/tmp/virusdetect.out
if [[ -s ~/tmp/virusdetect.out ]]
then
        echo "$fname: VIRUS FOUND!"
fi

done
