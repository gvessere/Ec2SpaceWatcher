#!/bin/bash

# assembles all loose drives into a raid0 at the next /dev/md{id} available

MOUNTPATH=/media/ebs
FILESYSTEMTYPE=xfs
# the list difference between xvd[b-z] drives and the drives already used in raids
NEWDRIVES=$( comm -23 <( ls /dev/xvd* | grep xvd[b-z] ) <( for array in `ls /dev/md*`; do mdadm --detail $array; done | grep /dev/xvd | tr -s " " | cut -d" " -f8 ) | tr "\n" " " )

NEXTRAID=`comm -23 <( seq -f "/dev/md%1.0f" 0 9 ) <( ls /dev/md* ) | head -1`
DEVICECOUNT=$( echo $NEWDRIVES | wc -w )

mdadm --create --verbose $NEXTRAID --chunk=256 --level=0 --name=$( echo Scratch$NEXTRAID | tr -d "/" ) --raid-devices=$DEVICECOUNT $NEWDRIVES
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
	mkfs.$FILESYSTEMTYPE $LVPATH
        mkdir -p $MOUNTPATH
	mount $LVPATH $MOUNTPATH
	echo "$LVPATH      $MOUNTPATH        $FILESYSTEMTYPE     defaults,noatime        0 0" | tee -a /etc/fstab
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

