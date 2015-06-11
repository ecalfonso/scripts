#!/bin/bash

TOKEN_FILE=~/.pushbullet/pb.token

# Error message function
error() {
        echo "Usage:"
        echo "	pb --note -t TITLE -m MESSAGE"
        echo "	pb --link -t TITLE -u URL -m MESSAGE"
        echo "	pb --addr -t TITLE -a ADDRESS"
        echo "	pb --set-token TOKEN"
        exit 1

}


# Check proper usage
if [[ $# -lt 2 ]]; then
	error
fi


# --set-token
if [[ $1 == "--set-token" ]]; then
	#test token first, token should be $2
	curl -u $2: https://api.pushbullet.com/v2/pushes -d type=note -d title="Successfully added token" > pb_tmp 2> /dev/null
	if grep -q error pb_tmp; then
		echo "Invalid token. Check if the token is correct."
		rm pb_tmp
		exit 1
	else
		echo "Succesfully added token!"
		rm pb_tmp
		if [ ! -d ~/.pushbullet ]; then
			mkdir ~/.pushbullet
		fi
		echo $2 > $TOKEN_FILE
		exit 0
	fi
fi


# Check if API key is set
if [[ ! -f $TOKEN_FILE ]]; then
	echo "No Pushbullet API key found!"
	echo "Find your access token at https://www.pushbullet.com/account"
	echo "To set API key: pb --set-token TOKEN"
	exit 1
else
	TOKEN=$(cat $TOKEN_FILE)
fi


# Check what type of push to send
case $1 in
"--note")	# Push a Note
	# Check for flag
	case $2 in
	"-t")	# Begins with title
		# Create and append to TITLE
		TITLE=$3
		while [[ $# -gt 3 ]]; do
			# When we hit -m
			if [[ $4 == "-m" ]]; then
				# Make message
				MSG=$5
				while [[ $# -gt 4 ]]; do
					shift
					MSG="$MSG $5"
				done
				break
			fi
			# Append to $TITLE
			TITLE="$TITLE $4"
			shift
		done

		# Check if title has input
		if [[ $TITLE == "" ]]; then
			echo "Error: No title input"
			error
		else
			echo "Sending Message..."
		        echo "Title: $TITLE"
		
		        # Check if message has input
		        if [[ $MSG == "" ]]; then
		                curl -u $TOKEN: https://api.pushbullet.com/v2/pushes -d type=note -d title="$TITLE" > /dev/null 2>&1
				echo "No message"
		        else
				echo "Sending message..."
		                echo "Message: $MSG"
		                curl -u $TOKEN: https://api.pushbullet.com/v2/pushes -d type=note -d title="$TITLE" -d body="$MSG" > /dev/null 2>&1
		        fi
		fi
	exit 0
	;;
	"-m")	# Message with no title
		# Create and append to Message
		MSG=$3
		while [[ $# -gt 3 ]]; do
			MSG="$MSG $4"
			shift
		done

		# Check if MSG is empty
		if [[ $MSG == "" ]]; then
			echo "Error: No message input"
			error
		else	# Send pushbullet
			#curl -u $TOKEN: https://api.pushbullet.com/v2/pushes -d type=note -d body="$MSG" > /dev/null 2>&1
			echo "Message: $MSG"
		fi
	exit 0
	;;
	*)
		# No flag specified
		echo "Error: No title or message specified"
		error
	esac	

	echo "Sending Message:"
	echo "Title: $TITLE"

	# If no message
	if [[ $MSG == "" ]]; then
		curl -u $TOKEN: https://api.pushbullet.com/v2/pushes -d type=note -d title="$TITLE" > /dev/null 2>&1
	else
		echo "Message: $MSG"
		curl -u $TOKEN: https://api.pushbullet.com/v2/pushes -d type=note -d title="$TITLE" -d body="$MSG" > /dev/null 2>&1
	fi

	exit 0
	;;


"--link")	# Push a Link
	echo "Link case"

	;;


"--addr")	# Push an Address
	echo "Address case"

	;;
*)		# Unknown push type
	echo "Error: Unknown push type"
	error
esac

#curl -u $PB_KEY: https://api.pushbullet.com/v2/pushes -d type=note -d title="Build Started for $DEVICE" -d body="Build-$DATE" > /dev/null 2>&1
