#!/bin/bash
CTID="$1"
CTIDHOSTNAME="$2"
CTIDIP="$3"

 curl -XPOST 'https://hooks.slack.com/services/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' -d '
 {"text":"'"$CTID"' - '"$CTIDHOSTNAME"' - '"$CTIDIP"' is using 95% or more disk.",
 "username":"Disk Monitor",
 "icon_url":"http://i.imgur.com/ea1KsVq.jpg"}'
