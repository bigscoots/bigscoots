#!/bin/bash

if pgrep -x "backupm" > /dev/null
  then
     vzpid $(pgrep backupm) | mail -s "$HOSTNAME has a malicious process running on container $(pgrep backupm) backupm" monitor@bigscoots.com
  else
     :
fi
