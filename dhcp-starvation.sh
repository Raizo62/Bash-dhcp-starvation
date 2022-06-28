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
      ifconfig $interface down

      # We switch our MAC address for out interface
      echo $(macchanger -a $interface)

      # We enable again our interface
      ifconfig $interface up

      # We get a new DHCP Lease
      dhclient $interface 2>&1 | grep DHCPACK
   done
fi
