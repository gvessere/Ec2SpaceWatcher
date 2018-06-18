#!/bin/bash

# find out the next size to use
DISKSIZES="100 400 1500 2000"
DISKCOUNT=6
# find out the next size by which to extend the drives based 
# on current number of md drives
let MDDRIVES=1+$( cat /proc/mdstat | grep md | wc -l )
DISKSIZE=`echo $DISKSIZES | cut -d" " -f$MDDRIVES`

./attachdrives.bash $DISKSIZE $DISKCOUNT

./createraid.bash

