#!/bin/bash

. common.bash

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

