#!/bin/bash

attempt=1
id=$(vzlist -H -o ctid | sed "1q;d")

until ! ps aux|grep -v grep | grep 'prlctl migrate' |grep "$id"
do
	echo "CTID $id is already being migrated."
	attempt=$((attempt+1))
	id=$(vzlist -H -o ctid | sed ""$attempt"q;d")
	echo "CTID $id will be attempted next."
done

echo ""
echo "CTID $id will now be migrated."
echo ""

vzlist -H -o ip $id \
| while read -r ip; do
if prlctl migrate $id $node --ssh="-p 2222"; then
sleep 5
 ssh -n -p 2222 $node "arping -c 2 -s $ip -U -I br0 $node"
 ssh -n -p 2222 $node "vzctl exec $id service mysql status"
fi
done