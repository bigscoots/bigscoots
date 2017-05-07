#!/bin/sh
find . -name '*.php' | while read fname
do
tail -n 1 $fname |grep -E '[0-9a-fA-F]{6}' > ~/tmp/virusdetect.out
if [[ -s ~/tmp/virusdetect.out ]]
then
        echo "$fname: VIRUS FOUND!"
fi
done
