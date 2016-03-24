#!/bin/sh

SMARTCMD="smartctl -B +./drivedb.h"

get_attached_devices() {
	DEVS=$( sysctl -n kern.disks | \
		tr ' ' '\n' | \
		sed '/^cd[0-9]*/d' | \
		sort )
	echo ${DEVS}
}

get_device_model() {
	DEVICE_MODEL=$( ${SMARTCMD} -i /dev/${1} | \
		grep "Device Model" | \
		awk -F\: '{print $2}' | \
		sed 's/^[ \t]*//' )
	echo ${DEVICE_MODEL}
}

get_device_capacity() {
	DEVICE_CAPACITY=$( ${SMARTCMD} -i /dev/${1} | \
		grep "User Capacity" | \
		awk -F\[ '{print $2}' | \
		sed 's/]//' )

	if [ -z "${DEVICE_CAPACITY}" ]; then
		DEVICE_CAPACITY=$( camcontrol readcap ${1} -H -s 2>/dev/null | \
			awk '{print $3,$4}' )

		if [ -n "${DEVICE_CAPACITY}" ]; then
			DEVICE_CAPACITY="${DEVICE_CAPACITY}B"
		fi
	fi

	echo ${DEVICE_CAPACITY}
}

get_device_temperature() {
	DEVICE_TEMP=$( ${SMARTCMD} -A -f brief /dev/${1} | \
		grep "Temperature_Celsius" | \
		awk '{print $8}' )
	echo ${DEVICE_TEMP}
}

get_device_partitions() {
	PARTITIONS=$( gpart show -p ${1} 2>/dev/null | \
		grep -Ev "GPT|MBR|- free -" | \
		awk '{print $3}' )

	if [ "${PARTITIONS}" == "" ]; then
		PARTITIONS="`gvfs-mount -l | grep ${1} | awk '{print $2}'`"
	fi

	echo "${PARTITIONS}"
}

get_mount_point() {
	MOUNT_POINT=$( mount | \
		grep -E "/dev/${1}|/media/${1}" | \
		awk '{print $3}' )
	echo ${MOUNT_POINT}
}

for DEV in $( get_attached_devices ); do
	MODEL=$( get_device_model ${DEV} )
	TEMP=$( get_device_temperature ${DEV} )
	CAPACITY=$( get_device_capacity ${DEV} )

	if [ "${TEMP}" != "" ]; then
		TEMP="[ ${TEMP} ℃ ]"
	fi

	printf "\${color 2A403D}\${font Poky:size=16}y\${font}\${color} \${color B53C27}\${hr}\${color}\n"
	printf "\${voffset -20}\${alignr}${MODEL} \n\n"
	printf "\${voffset -7} ${DEV} (${CAPACITY})\${alignr}${TEMP} \n"
	printf "\${voffset -4}\${color B53C27}\${stippled_hr}\${color}\n"
	
	for PARTITION in $( get_device_partitions ${DEV} ); do
		MP=$( get_mount_point ${PARTITION} )

		if [ "${MP}" != "" ]; then
			printf "\${goto 30}${MP}\${alignr}${PARTITION} \n"
			printf "\${voffset -3}\${goto 30}\${fs_bar 3,140 ${MP}}\n"
			printf "\${voffset -3}\${goto 30}\${alignr}\${fs_free ${MP}} / \${fs_size ${MP}} \n"
			printf "\${voffset -4}\${goto 30}\${color 7F8484}\${stippled_hr}\${color}\n"
		fi
	done
done

