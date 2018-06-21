#!/bin/bash

. common.bash

# find out the next size to use
DISKSIZES="100 400 1500 2000"
DISKCOUNT=6
# find out the next size by which to extend the drives based 
# on current number of md drives
MDDRIVES=$( cat /proc/mdstat | grep md | wc -l )
XVDRIVES=$( ls /dev/xvd* | grep -v xvda | wc -l )
let COL=1+$MDDRIVES
DISKSIZE=`echo $DISKSIZES | cut -d" " -f$COL`

if [[ (("$MDDRIVES" = "0") && ("$XVDRIVES" != "0") && ("$XVDRIVES" != "1")) && (-e /dev/xvdb) ]]; then
    echo "skip adding EBS drives this first time around, gonna use instance store"
else
    ./attachdrives.bash $DISKSIZE $DISKCOUNT
fi

./createraid.bash

