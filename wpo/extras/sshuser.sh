#!/bin/bash

# Create nginx user

mkdir -p /home/nginx/.ssh
touch /home/nginx/.ssh/authorized_keys
chmod 700 /home/nginx/.ssh
chmod 600 /home/nginx/.ssh/authorized_keys
sed -i 's=/home/nginx:/sbin/nologin=/home/nginx:/bin/bash=g' /etc/passwd

echo "SSH Host: $(ifconfig | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p')"
echo "SSH Port: 2222" 
echo "SSH Username: nginx"
echo "SSH Command: ssh -p 2222 nginx@$(ifconfig | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p')"
echo
echo
echo "Now add the customers SSH key to /home/nginx/.ssh/authorized_keys"
echo
echo