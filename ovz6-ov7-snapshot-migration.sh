#!/bin/bash
#!/usr/bin/expect

# Additional ssh opts, another key location for example
#SSH_OPTS="-i /root/id_rsa_target"
SSH_OPTS="-p 2222"
#SCP_OPTS="-P 2222"
SCP_OPTS="-P 2222"

function short_usage()
{

    echo "Usage: ./script.sh [--ctid|-c] [--server|-s] [--passwd|-p]

Run \"./script.sh --help\" for detailed help
"
    exit 1
}


function usage()
{
    echo "Usage: ./script.sh [--ctid|-c] [--server|-s]


NAME
        script.sh - script to copy ploop containers with snapshot. base image will be copied while container is running. then container is stopped delta is tranfered and container launched on destination.
SYNOPSIS
        ./script.sh [options]


        NOTE1: Use ssh root keys for passwordless access. Otherwise password will be asked 5 times.
        NOTE2: Containers should be located in /vz/private on both nodes. Make proper links or adjust this script if you have different paths.
        NOTE3: By default, container is not deleted from the source node, only unregistred.
        NOTE4: Please report all improvments to oasylov@virtuozzo.com

OPTIONS
        -c, --ctid
            Provide container id, this ctid of local container to migrate.

        -s, --server
            Provide destination server IP.

        -h, --help
            Print the help, that you just did.
COPYRIGHT
        Copyright (C) 1999-2018, Parallels IP Holdings GmbH. All rights reserved.
"
    exit 0
}

while [[ $# -gt 0 ]]
do
    key="${1}"

    case ${key} in
    -c| --ctid)
        CTID="${2}"
        shift # to next argument
        ;;
    -s| --server)
        SERVER="${2}"
        shift # to next argument
        ;;
#    -p| --passwd)
#        PASSWD="${2}"
#        shift # to next value
#        ;;
    -h|--help)
        usage
        ;;
#    *)    # unknown option
#        echo "ERROR: unknown parameter \"$PARAM\""
#        short_usage
#        shift # past argument
#        ;;
    esac
    shift
done


if [ -z "$CTID" ]
then
echo "no --ctid given, see --help for usage"
exit 1
fi

if [ -z "$SERVER" ]
then
echo "no --server given, see --help for usage"
exit 1
fi

#if [ -z "$PASSWD" ]
#then
#echo "no --passwd given, see --help for usage"
#exit 1
#fi


CTPATH=`vzlist -Ho  private $CTID`

#1. check if snapshot present
NUMSN=`ploop snapshot-list $CTPATH/root.hdd/DiskDescriptor.xml| wc -l`

if [ $NUMSN -eq 2 ] ; then
   echo "OK: snapshots not found continue "
   else
   echo "WARNING: snapshots exists, please merge all snapshost before continue e.g. making full backup"
   exit 1
fi

#2. make snapshot
echo "prlctl snapshot $CTID:"
vzctl snapshot $CTID

RESULT=$?
if [ $RESULT -ne 0 ] ; then
   echo "ERROR: making snapshot. check /var/log/ploop.log"
   exit 1
fi

#3. copy base image
echo "copy base image over ssh...(this might take a while)"
cd $CTPATH
tar --numeric-owner --sparse -zvc  /vz/private/$CTID/root.hdd/root.hdd  | ssh $SSH_OPTS root@$SERVER "mkdir -p /vz/private/$CTID/root.hdd && tar -zx -C /vz/private/$CTID/root.hdd --strip=4"

RESULT=$?
if [ $RESULT -ne 0 ] ; then
    echo "ERROR: tar or ssh failed"
    exit 1
fi

#4. stop container
vzctl stop $CTID

RESULT=$?
if [ $RESULT -ne 0 ] ; then
     echo "ERROR: CT stop failed failed"
     exit 1
fi


#5. copy delta image
SNAP=`ploop snapshot-list $CTPATH/root.hdd/DiskDescriptor.xml | sed '3!d' | grep "*"| awk '{print $4}'`
if [ -z "$SNAP" ]
then
echo "ERROR: more than one snapshot at this moment. Don't forget to start the container"
exit 1
fi

echo "copy delta to dst"

cd  $CTPATH
tar --numeric-owner --sparse -zvc  $SNAP  | ssh $SSH_OPTS root@$SERVER "mkdir -p /vz/private/$CTID/root.hdd && tar -zx -C /vz/private/$CTID/root.hdd --strip=4"
RESULT=$?
if [ $RESULT -ne 0 ] ; then
     echo "ERROR: tar or ssh failed. Don't forget to start the container"
     exit 1
fi

echo "final sync"

cd $CTPATH
tar --numeric-owner --sparse -zvc -C $CTPATH --exclude=./root.hdd/root.hdd --exclude=.owner . | ssh $SSH_OPTS root@$SERVER "mkdir -p /vz/private/$CTID && tar -zx -C /vz/private/$CTID"

RESULT=$?
if [ $RESULT -ne 0 ] ; then
      echo "ERROR: tar or ssh failed. Don't forget to start the container"
      exit 1
fi

#6. unregister CT on source
echo "Renaming config on source node to prevent it from starting up again"
echo "This does not remove the actual container."
echo "If migration fails, run:"
echo "mv -v /etc/vz/conf/$CTID.conf.migrated /etc/vz/conf/$CTID.conf"
echo "vzctl start $CTID"
mv -v /etc/vz/conf/$CTID.conf /etc/vz/conf/$CTID.conf.migrated


ssh $SSH_OPTS root@$SERVER ln -s 5 /vz/private/$CTID/.ve.layout

#7. register CT on dest

scp $SCP_OPTS /etc/vz/conf/$CTID.conf.migrated root@$SERVER:/vz/private/$CTID/ve.conf
[ $? -ne 0 ] && echo "Failed to copy Container config file"

# ssh root@$SERVER vzctl register /vz/private/$CTID --preserve-uuid
ssh $SSH_OPTS root@$SERVER vzctl register /vz/private/$CTID $CTID > /dev/null 2>&1
[ $? -ne 0 ] && echo "Failed to register Container $CTID"

#  merge any remaining snapshots
ssh $SSH_OPTS root@$SERVER ploop snapshot-merge -A /vz/private/$CTID/root.hdd/DiskDescriptor.xml

#8. strat CT
echo "starting CT on $SERVER"
ssh $SSH_OPTS root@$SERVER vzctl start $CTID

RESULT=$?
if [ $RESULT -ne 0 ] ; then
       echo "ERROR: CT start failed on dst"
       exit 1
    else
       echo "All should be done. Check CT $CTID on server $SERVER."
       exit 0
fi
