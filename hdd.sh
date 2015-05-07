#!/bin/sh

SMARTCMD="smartctl -B +./drivedb.h"

get_attached_devices() {
#	DEVS="`sysctl kern.disks | awk '{$1=""; ;print $0}' | awk 'gsub(" ", "\n")' | grep -v ^$ | sed '/^cd[0-9]/d' | sort`" 
	DEVS="`sysctl -n kern.disks | tr ' ' '\n' | sed '/^cd[0-9]*/d' | sort`" 
	echo ${DEVS}
}

get_device_model() {
	DEVICE_MODEL="`${SMARTCMD} -i /dev/${1} | grep "Device Model" | awk -F\: '{print $2}' | sed 's/^[ \t]*//'`"
	echo ${DEVICE_MODEL}
}

get_device_capacity() {
	DEVICE_CAPACITY="`${SMARTCMD} -i /dev/${1} | grep "User Capacity" | awk -F\[ '{print $2}' | sed 's/]//'`"
	echo ${DEVICE_CAPACITY}
}

get_device_temperature() {
	DEVICE_TEMP="`${SMARTCMD} -A -f brief /dev/${1} | grep "Temperature_Celsius" | awk '{print $8}'`"
	echo ${DEVICE_TEMP}
}

get_device_partitions() {
	PARTITIONS="`mount | grep /dev/${1} | grep -v none | awk '{print $1}' | sed 's/\/dev\///' | sort`"
	echo "${PARTITIONS}"
}

get_mount_point() {
	MOUNT_POINT="`mount | grep /dev/${1} | awk '{print $3}'`"
	echo ${MOUNT_POINT}
}

for DEV in `get_attached_devices`; do
	MODEL="`get_device_model ${DEV}`"
	TEMP="`get_device_temperature ${DEV}`"
	CAPACITY="`get_device_capacity ${DEV}`"

	if [ "${TEMP}" != "" ]; then
		TEMP="[ ${TEMP} ℃ ]"
	fi

#BEB9A5
	printf "\${color 2A403D}\${font Poky:size=16}y\${font}\${color} \${color B53C27}\${hr}\${color}\n"
	printf "\${voffset -20}\${alignr}${MODEL} \n\n"
	printf "\${voffset -7} ${DEV} (${CAPACITY})\${alignr}${TEMP} \n"
	printf "\${voffset -4}\${color B53C27}\${stippled_hr}\${color}\n"
	
	for PARTITION in `get_device_partitions ${DEV}`; do
		MP="`get_mount_point ${PARTITION}`"

		if [ "${MP}" != "" ]; then
			printf "\${goto 30}${MP}\${alignr}${PARTITION} \n"
			printf "\${voffset -3}\${goto 30}\${fs_bar 3,140 ${MP}}\n"
			printf "\${voffset -3}\${goto 30}\${alignr}\${fs_free ${MP}} / \${fs_size ${MP}} \n"
			printf "\${voffset -4}\${goto 30}\${color 7F8484}\${stippled_hr}\${color}\n"
		fi
	done
done
#printf "\n"

# ${font Poky:size=16}y${font} ${color B53C27}${stippled_hr}${color}
# ${voffset -18}${alignr}WDC WD2500AAKS-00F0A0
#
# ${voffset -4}ada2 (250 GB)${alignr}[ 41 ℃ ]
# ${voffset -4}${color B53C27}${hr}${color}

