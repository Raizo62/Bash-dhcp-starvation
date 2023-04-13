#!/bin/bash

if [[ -z $1 ]]; then
   interface='eth0'
else
   interface=$1
fi

while true; do
      # We kill every dhclient process
      killall dhclient
      rm -f /var/run/dhclient.pid

      # We disable our interface
      ip link set $interface down
      #ifconfig $interface down

      # We switch our MAC address for out interface
      macchanger -a $interface | grep '^New MAC:'

      # We enable again our interface
      ip link set $interface up
      #ifconfig $interface up

      # We get a new DHCP Lease
      dhclient -v $interface 2>&1 | grep DHCPACK
done
