#!/bin/bash 

AZ=`curl --silent http://169.254.169.254/2016-09-02/meta-data/placement/availability-zone/`
REGION="`echo \"$AZ\" | sed 's/[a-z]$//'`"
INSTANCEID=`curl --silent http://169.254.169.254/2016-09-02/meta-data/instance-id`
INSTANCETYPE=`curl --silent http://169.254.169.254/2016-09-02/meta-data/instance-type`

if [ -f /etc/spacewatcher.conf ];
then
 . /etc/spacewatcher.conf
 for var in `set | grep SPACEWATCHER_ | cut -d"=" -f1`; do export $var; done;
fi

vars=`set | egrep ^SPACEWATCHER | wc -l`

if [[ "$vars" == "0" ]]; 
then
 echo "using defaults"
 export SPACEWATCHER_GROWTHSEQUENCE_GB='110 400 1500 2000'
 export SPACEWATCHER_PARALLELISM=1
 export SPACEWATCHER_RAID_DRIVES=6
 export SPACEWATCHER_THRESHGB=40
 export SPACEWATCHER_THRESHPCT=90
 export SPACEWATCHER_MOUNTPOINT=/media/ebs
fi

function chr()
{
   ## convert number[s] to ASCII character[s]
   printf "%b" `printf '\x%x' $* 2>/dev/null`
   echo ""
}

MOUNTPATH=${SPACEWATCHER_MOUNTPOINT}
export -f chr
