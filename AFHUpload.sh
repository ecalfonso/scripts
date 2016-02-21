#!/bin/bash

if [[ -z $1 ]]; then
	echo "Usage: $0 [filename]"
	exit 1
fi

AFH_CONFIG=~/AFH.txt

if [ -e $AFH_CONFIG ]; then
        AFH_SERVER=`sed -n '1p' $AFH_CONFIG`
        AFH_USER=`sed -n '2p' $AFH_CONFIG`
        AFH_PASS=`sed -n '3p' $AFH_CONFIG`
else
        echoRed "AFH Config file not found!"
fi

echo "Uploading $1..."
sshpass -p $AFH_PASS scp -o StrictHostKeyChecking=no $1 $AFH_USER@$AFH_SERVER:/ 1> /dev/null 2>&1 || exit 1

exit 0
