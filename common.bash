#!/bin/bash 

AZ=`curl --silent http://169.254.169.254/2016-09-02/meta-data/placement/availability-zone/`
REGION="`echo \"$AZ\" | sed 's/[a-z]$//'`"
INSTANCEID=`curl --silent http://169.254.169.254/2016-09-02/meta-data/instance-id`
INSTANCETYPE=`curl --silent http://169.254.169.254/2016-09-02/meta-data/instance-type`

function chr()
{
   ## convert number[s] to ASCII character[s]
   printf "%b" `printf '\x%x' $* 2>/dev/null`
   echo ""
}

function isstatus()
{
	VOLUME=$1
	STATUS=$2
	state=$( aws ec2 --region us-east-1 describe-volumes --query "Volumes[?VolumeId==\`$VOLUME\`].State" )
	echo $state | grep "$STATUS"
	if [ "$?" == "0" ]; then
		echo 1
	else
		echo 0
	fi
}

function waitforstatus()
{
	VOLUME=$1
	STATUS=$2
	echo -n "waiting for volume status to transition to $STATUS"	
	while [ "$( isstatus $VOLUME $STATUS )" == "0" ]; do
		echo -n "."
		sleep .1
	done
	echo
}

