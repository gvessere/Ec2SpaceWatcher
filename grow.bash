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

# if no md drive and at least 2 local drives, then raid those, else add more disks
if [[ (($LVDISPLAY -eq 0) && ((-e /dev/xvdb && -e /dev/xvdc) || (-e /dev/nvme1n1 && -e /dev/nvme2n1))) ]]; then
    echo "skip adding EBS drives this first time around, gonna use instance store"
elif [[ (($LVDISPLAY -eq 0) && ( ((-e /dev/xvda) && (-e /dev/nvme0n1)) || ((-e /dev/xvdb) || (-e /dev/nvme0n1)) )) ]]; then
# extend a single instance drive to be part of a raid
# r3.2x  /dev/xvda /dev/xvdb (*)
# f1.2x  /dev/xvda /dev/nvme0n1 (*)
# c4.8x  /dev/xvda 
# cc2.8x /dev/xvda /dev/xvdb /dev/xvdc /dev/xvdd /dev/xvde
# c5.9x  /dev/nvme0n1 

    if [[ -e /dev/xvdb ]]; then
        DEVICE=/dev/xvdb
    else
        DEVICE=/dev/nvme0n1
    fi

    # decrement total disks and recompute total size
    # to make the most out of the local drive
    let DISKCOUNT=$DISKCOUNT-1
    let DISKSIZE=(`blockdev --getsize64 $DEVICE`/1024/1024/1024-2)*$DISKCOUNT
    ./attachdrives.bash $DISKSIZE $DISKCOUNT
else
    ./attachdrives.bash $DISKSIZE $DISKCOUNT
fi

./createraid.bash

