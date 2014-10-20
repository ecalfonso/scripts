#!/bin/bash

IP_ADDR=192.168.0

if [[ $1 == "" ]]; then
	echo "Error: No mac list specified"
	echo "Usage: nmap_scan.sh mac_list"
	exit 1
fi

FILE=$1

for i in {1..254}
do
	CURR_MAC=$(nmap -sP $IP_ADDR.$i | grep MAC | cut -d " " -f 3)

	if [[ $CURR_MAC != "" ]]; then
		echo "$CURR_MAC on $IP_ADDR.$i"
		if grep -q $CURR_MAC $FILE; then
			grep $CURR_MAC $FILE | cut -f 2
		else
			echo "$CURR_MAC is an unknown device!"
		fi
		echo ""
	fi
done
