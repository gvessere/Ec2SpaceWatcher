#!/bin/bash

# assembles all loose drives into a raid0 at the next /dev/md{id} available
. common.bash 

FILESYSTEMTYPE=xfs
# the list difference between xvd[b-z] drives and the drives already used in raids
# nvm instance (like c5s) have different names for their drives (eg. /dev/nvme1n1)

# list attached drives
LIST=	
DRIVEPATTERN=/dev/nvme
POSSIBLEDRIVES="nvme[0-9]+n1$"
LIST="$LIST `ls $DRIVEPATTERN* 2> /dev/null | egrep $POSSIBLEDRIVES`"

DRIVEPATTERN=/dev/xvd
POSSIBLEDRIVES="xvd[a-z]$"
LIST="$LIST `ls $DRIVEPATTERN* 2> /dev/null | egrep $POSSIBLEDRIVES`"

INUSE=`lsblk -n --output MOUNTPOINT,KNAME,PKNAME | tr -s " " | cut -d" " -f3 | grep -v "^$" | sort | uniq | sort -k1.10 -n | xargs -I{} echo /dev/{}`


NEWDRIVES=$( comm -23 <( echo $LIST | tr " " "\n" | sort -k1.10 -n ) <( echo $INUSE | tr " " "\n" ) | tr "\n" " " )

for DRIVE in $NEWDRIVES;
do
	umount $DRIVE 2> /dev/null
done

NEXTRAID=`comm -23 <( seq -f "/dev/md%1.0f" 0 9 ) <( ls /dev/md* ) | head -1`
DEVICECOUNT=$( echo $NEWDRIVES | wc -w )

if [[ $DEVICECOUNT -gt 1 ]]; then
	yes | mdadm --create --verbose $NEXTRAID --chunk=256 --level=0 --name=$( echo $NEXTRAID | tr -d "/" ) --raid-devices=$DEVICECOUNT $NEWDRIVES
	mdadm --detail --brief $NEXTRAID | sudo tee -a /etc/mdadm/mdadm.conf
	NEXTDRIVE=$NEXTRAID
else
	# should be 1 drive only
	NEXTDRIVE=$NEWDRIVES
fi

pvcreate $NEXTDRIVE

HASVG=`vgdisplay | grep "vg_data" | wc -l`

if [[ "$HASVG" == "0" ]]; then
	# this should be done once only
	# create volume group
	vgcreate vg_data $NEXTDRIVE
	# create logical volume
	lvcreate -l 100%FREE -n lv_data vg_data
	LVPATH=`lvdisplay | grep Path | tr -s " " | cut -d" " -f4`
	# create filesystem
	mkfs.$FILESYSTEMTYPE -K $LVPATH
	mkdir -p $MOUNTPATH
	# mount filesystem
	mount $LVPATH $MOUNTPATH
	echo "$LVPATH	  $MOUNTPATH	$FILESYSTEMTYPE	 defaults,noatime	0 0" | tee -a /etc/fstab

	if ! grep -q "$MOUNTPATH" /proc/mounts; then
        	echo "***"
        	echo "*** Failed to mount $MOUNTPATH. Shutting down. "
        	echo "***"
        	shutdown now
    	fi
else
	# it exists already so extend it
	LVPATH=`lvdisplay | grep Path | tr -s " " | cut -d" " -f4`
	vgextend vg_data $NEXTDRIVE
	lvextend -l 100%VG $LVPATH $NEXTDRIVE
	if [[ "$FILESYSTEMTYPE" = "xfs" ]]; then
		xfs_growfs $LVPATH
	else
		resize2fs $LVPATH
	fi
fi

