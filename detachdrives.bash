#!/bin/bash

. common.bash

VOLUMES=`aws ec2 --region $REGION describe-volumes --query "Volumes[?Tags[?Value=='$INSTANCEID']].VolumeId" | tr -d '"[],' | perl -pe "s/^ //"`
echo $VOLUMES | xargs -n 1 -P26 -I{} bash -c "aws ec2 --region $REGION detach-volume --volume-id {} || true"

# this step takes a lot longer on c5 instances (30s for c4, ~3-5 minutes for c5)
for VOL in $VOLUMES;
do
	waitforstatus $VOL available
done

for VOL in $VOLUMES;
do
	aws ec2 --region $REGION delete-volume --volume-id $VOL
done

