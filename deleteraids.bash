#!/bin/bash

LVPATH=`lvdisplay | grep Path | tr -s " " | cut -d" " -f4`

umount /media/ebs

lvremove /dev/vg_data/lv_data -y
vgremove vg_data
for dev in `ls /dev/md*`; do 
	mdadm --stop $dev; 
done
for dev in {b..z}; do
	mdadm --zero-superblock /dev/xvd$dev 2> /dev/null
done
echo > /etc/mdadm/mdadm.conf
