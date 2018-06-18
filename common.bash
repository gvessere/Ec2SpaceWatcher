#!/bin/bash 

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

