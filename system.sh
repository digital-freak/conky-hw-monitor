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

rm -f system.rc

cat templates/system.tmpl | \
	sed -E "s/\[cpu_name\]/${CPU_NAME}/;
	s/\[cpu_speed\]/${CPU_SPEED}/;
	s/\[cpu_load\]/${CPU_LOAD}/" >> ./system.rc

conky -c system.rc &
exit 0
