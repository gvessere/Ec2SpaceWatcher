#!/bin/bash

# assembles all loose drives into a raid0 at the next /dev/md{id} available
. common.bash 

MOUNTPATH=/media/ebs
FILESYSTEMTYPE=xfs
# the list difference between xvd[b-z] drives and the drives already used in raids
# nvm instance (like c5s) have different names for their drives (eg. /dev/nvme1n1)
if [[ -e /dev/nvme0 ]];
then
	DRIVEPATTERN=/dev/nvme
	POSSIBLEDRIVES="nvme[1-9][0-9]*n1$" # this excludes nvme0
else
	DRIVEPATTERN=/dev/xvd
	POSSIBLEDRIVES="xvd[b-z]$"
fi
NEWDRIVES=$( comm -23 <( ls $DRIVEPATTERN* | egrep $POSSIBLEDRIVES | sort -k1.10 -n ) <( for array in `ls /dev/md* 2> /dev/null`; do mdadm --detail $array; done | grep $DRIVEPATTERN | tr -s " " | cut -d" " -f8 ) | sort -k1.10 -n | tr "\n" " " )

NEXTRAID=`comm -23 <( seq -f "/dev/md%1.0f" 0 9 ) <( ls /dev/md* ) | head -1`
DEVICECOUNT=$( echo $NEWDRIVES | wc -w )

for DRIVE in $NEWDRIVES;
do
	umount $DRIVE 2> /dev/null
done

yes | mdadm --create --verbose $NEXTRAID --chunk=256 --level=0 --name=$( echo Scratch$NEXTRAID | tr -d "/" ) --raid-devices=$DEVICECOUNT $NEWDRIVES
mdadm --detail --brief $NEXTRAID | sudo tee -a /etc/mdadm/mdadm.conf
update-initramfs -u

pvcreate $NEXTRAID

HASVG=`vgdisplay | grep "vg_data" | wc -l`

if [[ "$HASVG" == "0" ]]; then
	# this should be done once only
	# create volume group
	vgcreate vg_data $NEXTRAID
	# create logical volume
	lvcreate -l 100%FREE -n lv_data vg_data
	LVPATH=`lvdisplay | grep Path | tr -s " " | cut -d" " -f4`
	# create filesystem
	mkfs.$FILESYSTEMTYPE $LVPATH
	mkdir -p $MOUNTPATH
	# mount filesystem
	mount $LVPATH $MOUNTPATH
	echo "$LVPATH	  $MOUNTPATH	$FILESYSTEMTYPE	 defaults,noatime	0 0" | tee -a /etc/fstab
else
	# it exists already so extend it
	LVPATH=`lvdisplay | grep Path | tr -s " " | cut -d" " -f4`
	vgextend vg_data $NEXTRAID
	lvextend -l 100%VG $LVPATH $NEXTRAID
	if [[ "$FILESYSTEMTYPE" = "xfs" ]]; then
		xfs_growfs $LVPATH
	else
		resize2fs $LVPATH
	fi
fi

