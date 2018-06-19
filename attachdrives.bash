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

for i in `seq 1 $DISKCOUNT`; do
	VOLUME=`aws ec2 --region $REGION create-volume --tag-specifications "ResourceType='volume',Tags=[{Key=Name,Value=Instance Drive}, {Key=ManagedBy,Value=$INSTANCEID}]" --volume-type gp2 --availability-zone $AZ --encrypted --size $DISKSIZE | jq ".VolumeId" | tr -d '"'`

	if [[ "${INSTANCETYPE:0:2}" = "c5" ]];
	then
		alldrives=`echo /dev/nvme{1..25} `
		actualdrives=`ls /dev/nvme* | tr " " "\n" | sort -k1.10 -n | egrep "nvme[[:digit:]]+$" | egrep -v "nvme0$" `
	else
		alldrives=`echo /dev/xvd{b..z}`
		actualdrives=`ls /dev/xvd* | tr " " "\n" | grep -v "xvda"`
	fi

	DEVICE=`comm --nocheck-order -23 <( echo $alldrives | tr " " "\n") <( echo $actualdrives | tr " " "\n" ) | head -1`
	
	# need to reconvert that device back to xvd naming for making the api call
	if [[ "${INSTANCETYPE:0:2}" = "c5" ]];
	then
		let drive=97+${DEVICE:9}
		DEVICEXV=/dev/xvd$( chr $drive )
	fi

	echo Adding device $DEVICE
	waitforstatus $VOLUME available
	aws ec2 --region $REGION attach-volume --volume-id $VOLUME --instance-id $INSTANCEID --device $DEVICEXV
	waitforstatus $VOLUME in-use
	waitfordevice $DEVICE
done

sleep 5
