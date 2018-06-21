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

function attachdrive()
{
	DEVICE=$1
	XVDEVICE=$2
	VOLUME=$3

	echo Adding device $DEVICE
	attachedtest=1
	until [[ $attachedtest -eq 0 ]]; do
		attachedtest=`aws ec2 --region $REGION attach-volume --volume-id $VOLUME --instance-id $INSTANCEID --device $XVDEVICE 2>&1 | grep -q VolumeInUse; echo $?`
		sleep .5
	done
	
	aws ec2 --region $REGION modify-instance-attribute --instance-id $INSTANCEID --block-device-mappings DeviceName=$XVDEVICE,Ebs={DeleteOnTermination=true}

	waitfordevice $DEVICE
}

DISKCOUNT=${2:-6}
TOTALSIZE=${1:-333}
DISKSIZE=$((TOTALSIZE/DISKCOUNT))

echo "adding $DISKCOUNT drives of size $DISKSIZE"

TMP=`mktemp -up /tmp`
mkdir -p $TMP

export REGION INSTANCEID AZ DISKSIZE TMP

# create volumes
seq 1 $DISKCOUNT | xargs -I{} -P 6 bash -c "aws ec2 --region $REGION create-volume --volume-type gp2 --availability-zone $AZ --encrypted --size $DISKSIZE | jq \".VolumeId\" | tr -d '\"' > $TMP/{}"

aws --region $REGION ec2 create-tags --resources `cat $TMP/* | tr "\n" " "` --tags Key=Name,Value="Instance Drive" Key=ManagedBy,Value=$INSTANCEID 

for VOLUME in `cat $TMP/*`; do
	if [[ -e /dev/nvme0 ]];
	then
		alldrives=`echo /dev/nvme{1..25} `
		actualdrives=`ls /dev/nvme* | tr " " "\n" | sort -k1.10 -n | egrep "nvme[[:digit:]]+$" | egrep -v "nvme0$" `
	else
		alldrives=`echo /dev/xvd{b..z}`
		actualdrives=`ls /dev/xvd* | tr " " "\n" | grep -v "xvda"`
	fi

	DEVICE=`comm --nocheck-order -23 <( echo $alldrives | tr " " "\n") <( echo $actualdrives | tr " " "\n" ) | head -1`
	
	# need to reconvert that device back to xvd naming for making the api call
	DEVICEXV=$DEVICE

	if [[ -e /dev/nvme0 ]];
	then
		let drive=97+${DEVICE:9}
		DEVICEXV=/dev/xvd$( chr $drive )
	fi

	attachdrive $DEVICE $DEVICEXV $VOLUME
done

rm -Rf $TMP

sleep 5
