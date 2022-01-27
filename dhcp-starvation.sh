#!/bin/bash

while true; do
   # We kill every dhclient process
   killall dhclient
   rm -f /var/run/dhclient.pid

   # We disable our interface
   ifconfig eth0 down

   # We switch our MAC address for out interface
   echo $(macchanger -a eth0)

   # We enable again our interface
   ifconfig eth0 up

   # We get a new DHCP Lease
   dhclient eth0 2>&1 | grep DHCPACK
done
