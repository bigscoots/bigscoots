#!/bin/bash
trigger=$(grep pro /proc/cpuinfo -c)
load=`cat /proc/loadavg | awk '{print $1}'`
response=`echo | awk -v T=$trigger -v L=$load 'BEGIN{if ( L > T){ print "greater"}}'`
if [[ $response = "greater" ]]
then
sar -q | mail -s"High load on server - $HOSTNAME [ $load ] -" monitor@bigscoots.com
fi
