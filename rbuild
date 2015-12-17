#!/bin/bash

# Set time
DATE=$(date +"%Y%m%d-%T")
KERNEL_DATE=$(date +"%Y%m%d")

# Initialize build variables
AFH=0		# Upload to AFH
ALL=0		# To build all jf variants
RELEASE=0	# To move output zips to final dir or not
ROM=0		# Set to 1 to Build ROM
SYNC=0		# Sync source
WIPE=0		# Fully wipe before build

# Script constants
OUT_DIR=/home/ecalfonso/Android/
AFH_CONFIG=AFH.txt

# Bash colors
RED='\033[0;31m'; GRE='\033[0;32m'; NC='\033[0m'

# Functions
function echoStatus { 
	# $1 - What to echo

	echo " "
	echo -e "${GRE}#########################################"
	echo "#"
	echo "# $1"
	echo "#"
	echo -e "#########################################${NC}"
	echo " "
} # echoStatus

function elapsedTime {
    END=$(date +%s.%N)
    HOUR=$(echo "(($END-$START)/3600)"|bc)
    MIN=$(echo "(($END-$START)/60)%60"|bc)
    SEC=$(echo "($END-$START)%60"|bc)

    echo "Elapsed time: $HOUR hr $MIN min $SEC sec"
} # elapsedTime

function pbBeginMsg {
	# $1 - Build variant
	
	pb -s "Starting $1 build for $DEVICE @ $DATE"
} # pbBeginMsg

function pbErrorMsg {
	# $1 - Build variant
	# $2 - Where the build failed
	
	pb -s "$1 build failed during $2 for $DEVICE" "$(elapsedTime)"
	
	exit 1
} # pbErrorMsg

function pbSuccessMsg {
	# $1 - Build variant
	
	pb -s "$1 build complete for $DEVICE" "$(elapsedTime)"
} # pbSuccessMsg

function setEnv {
	echoStatus "Setting Environment"

	if [ ! -f build/envsetup.sh ];
	then
		echo -e "${RED}Error setting up environment${NC}";
		pbErrorMsg " " "Environment setup"
	fi

	. build/envsetup.sh >/dev/null 2>&1
} # setEnv

function syncTree {
	echoStatus "Syncing repos"

	reposync --force-sync || {
		echo -e "${RED}Error syncing repo${NC}"
		pbErrorMsg " " "Repo sync"
	}
} # syncTree

function wipeTree {
	echoStatus "Cleaning build directory"

	rm -rf ~/cm13/.ccache > /dev/null 2>&1 || { echo -e "${RED}Error removing ccache${NC}"; pbErrorMsg " " "Ccache removal"; }
	mka clean > /dev/null 2>&1 || { echo -e "${RED}Error making clean${NC}"; pbErrorMsg " " "Making Clean"; }
	if ls logs/*.log 1> /dev/null 2>&1; then
		rm logs/*.log
	fi
} # wipeEnv

function buildROM {
	echoStatus "Starting ROM build"
	lunch cm_$DEVICE-userdebug >/dev/null 2>&1
	mka otapackage 2>&1 | tee logs/$DEVICE-$DATE.log
} # buildROM

function checkROMMake() {	
	if [ -e logs/$DEVICE-$DATE.log ]; then
		if tail logs/$DEVICE-$DATE.log | grep -q "make completed successfully"; then
			# Send alert
			pbSuccessMsg "ROM"

			if [[ $RELEASE == 1 ]]; then
				# Copy latest ota and target-files to repository
				echo -e "${GRE}Copying OTA to repository${NC}"
				cp `ls -t out/target/product/$DEVICE/*$DEVICE*.zip | head -1` $OUT_DIR
			fi
			return 0
		fi
	fi
	pbErrorMsg "ROM" "Building"
	exit 1
} # checkROMMake

function uploadROM {
	# Get AFH configs
	if [ -e $AFH_CONFIG ]; then
		AFH_SERVER=`sed -n '1p' $AFH_CONFIG`
		AFH_USER=`sed -n '2p' $AFH_CONFIG`
		AFH_PASS=`sed -n '3p' $AFH_CONFIG`
	else
		echo -e "${RED}No AFH config file to read from!${NC}"
		exit 1
	fi

	# Get latest ROM
	ROM=`ls -t out/target/product/$DEVICE/*$DEVICE*.zip | head -n 1`
	ROM_NAME=`cd out/target/product/$DEVICE/ && ls -t *$DEVICE*.zip | head -n 1`
	echoStatus "Uploading $ROM to AFH"

	sshpass -p $AFH_PASS scp -o StrictHostKeyChecking=no $ROM $AFH_USER@$AFH_SERVER:/
	
	# Pushbullet notify upload is complete
	pb -s "ROM for $DEVICE uploaded to AndroidFileHost" "$ROM_NAME MD5: `md5sum $ROM | cut -d" " -f1`"
} # uploadROM

# Trap handling
trap ctrl_c INT
function ctrl_c() {
	echo -e "{$RED}** User aborted!!!${NC}"
	pb -s "User aborted during $DEVICE build!"
	exit 1
}

#
# BEGIN SCRIPT
#
# Loop through arguments
for var in "$@"
do
	case "$var" in
		afh) AFH=1;;
		all) ALL=1;;
		release) RELEASE=1;;
		rom) ROM=1;;
		sync) SYNC=1;;
		wipe) WIPE=1;;
		*) echo -e "${RED}Unknown parameter $var\n${NC}";;
	esac
done

# Begin build script
if [[ $ROM == 1 ]]; then
	setEnv
else
	echo -e "${RED}Usage: $0 kernel rom sync wipe"
	echo "	afh - Upload ROM to AFH FTP"
	echo "	all - build for all variants"
	echo "	release - copy ota to output dir"
	echo "	rom - build ROM"
	echo "	sync - Sync repos"
	echo -e "	wipe - Clean build directory${NC}"
	exit 1
fi

if [[ $SYNC == 1 ]]; then
	syncTree
fi

if [[ $WIPE == 1 ]]; then 
	wipeTree
fi

if [[ $ROM == 1 ]]; then
	# Build all variants
	for DEVICE in \
		jfltegsm \
		jfltecdma
		do

		START=$(date +%s.%N)
		pbBeginMsg "ROM"
		buildROM
      		checkROMMake
		if [[ $AFH == 1 ]]; then
			uploadROM
		fi
	done
fi
