#!/bin/bash

. common.bash

function waitfordevice()
{
    DEVICE=$1
    echo -n "waiting for device to show up"    
    while [ "$( ls $DEVICE 2> /dev/null | wc -l )" == "0" ]; do
      echo -n "."
      sleep .1
    done
    echo
}

DISKCOUNT=${2:-6}
TOTALSIZE=${1:-333}
DISKSIZE=$((TOTALSIZE/DISKCOUNT))

echo "adding $DISKCOUNT drives of size $DISKSIZE"

AZ=`curl http://169.254.169.254/2016-09-02/meta-data/placement/availability-zone/`
REGION="`echo \"$AZ\" | sed 's/[a-z]$//'`"
INSTANCEID=`curl http://169.254.169.254/2016-09-02/meta-data/instance-id`

for i in `seq 1 $DISKCOUNT`; do
 VOLUME=`aws ec2 --region $REGION create-volume --tag-specifications "ResourceType='volume',Tags=[{Key=Name,Value=Instance Drive}, {Key=ManagedBy,Value=$INSTANCEID}]" --volume-type gp2 --availability-zone $AZ --encrypted --size $DISKSIZE | jq ".VolumeId" | tr -d '"'`

 DEVICE=`comm -23 <( for c in {b..z}; do echo /dev/xvd$c; done ) <( ls /dev/xvd* | tr " " "\n" | grep -v "xvda" ) | head -1`
 echo Adding device $DEVICE
 waitforstatus $VOLUME available
 aws ec2 --region $REGION attach-volume --volume-id $VOLUME --instance-id $INSTANCEID --device $DEVICE
 waitforstatus $VOLUME in-use
 waitfordevice $DEVICE
done

sleep 5
