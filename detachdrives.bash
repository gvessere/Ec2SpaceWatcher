#!/bin/bash

. common.bash

AZ=`curl http://169.254.169.254/2016-09-02/meta-data/placement/availability-zone/`
REGION="`echo \"$AZ\" | sed 's/[a-z]$//'`"
INSTANCEID=`curl http://169.254.169.254/2016-09-02/meta-data/instance-id`

VOLUMES=`aws ec2 --region $REGION describe-volumes --query "Volumes[?Tags[?Value=='$INSTANCEID']].VolumeId" | tr -d '"[],' | perl -pe "s/^ //"`


echo $VOLUMES | xargs -n 1 -P26 aws ec2 --region $REGION detach-volume --volume-id $VOL

for VOL in $VOLUMES;
do
	waitforstatus $VOL available
done

for VOL in $VOLUMES;
do
        aws ec2 --region $REGION delete-volume --volume-id $VOL
done

