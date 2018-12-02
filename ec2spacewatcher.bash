#!/bin/bash

. common.bash

function NeedsGrow()
{
	THRESHPCT=${SPACEWATCHER_THRESHGB}
	let LOWAVAIL_BYTES=${SPACEWATCHER_THRESHGB}*1024*1024*1024
	let MDDRIVESMAX=24/SPACEWATCHER_RAID_DRIVES
	DEVICE=/dev/mapper/vg_data-lv_data
	USAGEPCT=$( df | grep $DEVICE | tr -s " " | cut -d" " -f5 )
	USAGEPCT=${USAGEPCT/\%/}
	USAGEPCT=${USAGEPCT:-0}
	AVAIL=$( df | grep $DEVICE | tr -s " " | cut -d" " -f4 )
	AVAIL=${AVAIL:-0}
	# correct for df units
	AVAIL=$((AVAIL*1024))
	CREATEDMD=`ls /dev/md* | grep -v "md/" | wc -l`
	echo $((((USAGEPCT>THRESHPCT) || (AVAIL<LOWAVAIL_BYTES)) && CREATEDMD<MDDRIVESMAX ))
}

while true; do

if [[ "$( NeedsGrow )" == "1" ]]; then
	echo "expanding drive"
	./grow.bash
fi

sleep 1
done

