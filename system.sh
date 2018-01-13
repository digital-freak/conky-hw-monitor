#!/bin/sh

CPU_NAME="`sysctl -n hw.model | \
	sed 's/(R)//;s/(TM)//' | \
	sed -E 's/[[:space:]]+/ /g' | \
	awk -F\@ '{print $1}' | \
	sed -E 's/[[:space:]]+$//'`"
CPU_SPEED="`sysctl -n hw.model | \
	sed 's/(R)//;s/(TM)//' | \
	sed -E 's/[[:space:]]+/ /g' | \
	awk -F\@ '{print $2}' | \
	sed -E 's/^[[:space:]]+//'`"
CPU_CORES="`sysctl -n hw.ncpu`"

CPU_LOAD=""
NET_LOAD=""

if [ ${CPU_CORES} -eq 1 ]; then
	CPU_LOAD='${goto 30}[cpu_temp]\
${voffset -2}${goto 30}${cpubar cpu0 3,140}'
else
	N=0
	while [ ${N} != ${CPU_CORES} ]; do
		POS=$((${N} % 2))

		if [ ${POS} -eq 0 ]; then
			CORE_TEMP='${goto 30}${lua cpu_temperature '${N}'}'
			CORE_LOAD='${voffset -4}${goto 30}${cpubar cpu'$((N+1))' 3,60}'
		else
			CORE_TEMP=${CORE_TEMP}'${alignr}${offset -3}${lua cpu_temperature '${N}'}'
			CORE_LOAD=${CORE_LOAD}'${alignr}${offset -3}${cpubar cpu'$((N+1))' 3,60}'
			if [ ${N} -gt 1 ]; then
				CPU_LOAD=${CPU_LOAD}'\
'${CORE_TEMP}'\
'${CORE_LOAD}
			else
				CPU_LOAD=${CORE_TEMP}'\
'${CORE_LOAD}
			fi
			CORE_TEMP=""
			CORE_LOAD=""
		fi

		N=$((N + 1))
	done
fi

case "$( uname )" in
	"FreeBSD" )
		IFACES=$( ifconfig -lu | sed 's/lo[0-9]*//' );;
	"Linux" )
		IFACES=$( ifconfig -s | awk '{print $1}' | sed '1d;/lo/ c\' );;
	* )
		;;
esac

for IFACE in ${IFACES}; do
	ETHER=$( ifconfig ${IFACE} | grep ether | awk '{print $2}' )
	INET=$( ifconfig ${IFACE} | grep inet | awk '{print $2}' )
	NL='${color 2A403D}${font Poky:size=16}w${font} ${color B53C27}${hr}${color}\
${voffset -20}${goto 30}'${IFACE}'${alignr}${offset -3}'${INET}'\
${voffset 5}${alignr}${offset -3}'${ETHER}'\
${voffset 5}${goto 30}↑${alignr}${offset -15}${upspeed '${IFACE}'}${offset -172}${alignr}${offset -3}${voffset -7}${upspeedgraph '${IFACE}' 16,60}\
${goto 30}↓${alignr}${offset -15}${downspeed '${IFACE}'}${offset -172}${alignr}${offset -3}${voffset -7}${downspeedgraph '${IFACE}' 16,60}\
${voffset -4}${goto 30}${color 7F8484}${stippled_hr}${color}'

	NET_LOAD=${NET_LOAD}${NL}'\
'
done

rm -f system.rc

cat templates/system.tmpl | \
	sed -E "s/\[cpu_name\]/${CPU_NAME}/;
	s/\[cpu_speed\]/${CPU_SPEED}/;
	s/\[cpu_load\]/${CPU_LOAD}/;
	s/\[net_load\]/${NET_LOAD}/" >> ./system.rc

conky -c system.rc &
exit 0
