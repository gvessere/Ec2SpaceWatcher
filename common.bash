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

export -f chr
