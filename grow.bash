#!/bin/bash

. common.bash

# find out the next size to use
DISKSIZES="110 400 1500 2000"
DISKCOUNT=6
# find out the next size by which to extend the drives based 
# on current number of md drives
MDDRIVES=$( cat /proc/mdstat | grep md | wc -l )
LVDISPLAY=$( lvdisplay | grep /dev/vg_data/lv_data | wc -l )

let COL=1+$MDDRIVES
DISKSIZE=`echo $DISKSIZES | cut -d" " -f$COL`

# if no md drive and at least 1 local drive, then raid those, else add more disks
if [[ (($LVDISPLAY -eq 0) && ((-e /dev/xvdb ) || (-e /dev/nvme1n1))) ]]; then
    echo "skip adding EBS drives this first time around, gonna use instance store"
else
    ./attachdrives.bash $DISKSIZE $DISKCOUNT
fi

./createraid.bash

