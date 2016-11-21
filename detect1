#!/bin/sh
find . -name '*.php' | while read fname
do
head -1 $fname |grep base64 > ~/tmp/virusdetect.out
if [[ -s ~/tmp/virusdetect.out ]]
then
        echo "$fname: VIRUS FOUND!"
fi
if egrep -q '[a-f0-9A-F]{70}' $fname
then
        echo "$fname: VIRUS FOUND!"
fi
if egrep -q '\\[xX][0-9a-fA-F][0-9a-fA-F]\\[xX][0-9a-fA-F][0-9a-fA-F]' $fname
then
       echo "$fname: VIRUS FOUND!"
fi
done
