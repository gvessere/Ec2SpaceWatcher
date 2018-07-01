#!/bin/bash

function NeedsGrow()
{
	THRESHPCT=90
	let LOWAVAIL_BYTES=30*1024*1024*1024

	DEVICE=/dev/mapper/vg_data-lv_data
	USAGEPCT=$( df | grep $DEVICE | tr -s " " | cut -d" " -f5 )
	USAGEPCT=${USAGEPCT/\%/}
	USAGEPCT=${USAGEPCT:-0}
	AVAIL=$( df | grep $DEVICE | tr -s " " | cut -d" " -f4 )
	AVAIL=${AVAIL:-0}
	# correct for df units
	AVAIL=$((AVAIL*1024))

	echo $(((USAGEPCT>THRESHPCT) || (AVAIL<LOWAVAIL_BYTES)))
}

while true; do

if [[ "$( NeedsGrow )" == "1" ]]; then
	./grow.bash
fi

sleep 1
done

