#!/bin/bash

# Set time
DATE=$(date +"%Y%m%d-%T")
KERNEL_DATE=$(date +"%Y%m%d")
START=$(date +%s.%N)

# Initialize build variables
INCREMENTAL=0	# For incremental OTAs
KERNEL=0	# Set to 1 to build kernel
RELEASE=0	# To move output zips to final dir or not
ROM=0		# Set to 1 to Build ROM
PREBUILT=0	# Whether or not to pick prebuilt boot.img
SYNC=0		# Sync source
TEST=0
WIPE=0		# Fully wipe before build

# Script constants
DEVICE=jflte
BOOT_IMG=out/target/product/$DEVICE/boot.img
KERNEL_ZIP_DIR=kernel/samsung/jf/zip/
OUT_DIR=/home/ecalfonso/Android/
TARGET_FILES_OUT_DIR=/home/ecalfonso/target-files/

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
	
	$(pb "Starting $1 build for $DEVICE @ $DATE")
} # pbBeginMsg

function pbErrorMsg {
	# $1 - Build variant
	# $2 - Where the build failed
	
	$(pb "$1 build failed during $2 for $DEVICE" `elapsedTime`)
	
	exit 1
} # pbErrorMsg

function pbSuccessMsg {
	# $1 - Build variant
	
	$(pb "$1 build complete for $DEVICE" `elapsedTime`)
} # pbSuccessMsg

function setEnv {
	echoStatus "Setting Environment"

	if [ ! -f build/envsetup.sh ];
	then
		echo -e "${RED}Error setting up environment${NC}";
		pbErrorMsg " " "Environment setup"
	fi

	. build/envsetup.sh >/dev/null 2>&1
	lunch cm_$DEVICE-userdebug >/dev/null 2>&1
} # setEnv

function syncTree {
	echoStatus "Syncing repos"

	reposync || {
		echo -e "${RED}Error syncing repo${NC}"
		pbErrorMsg " " "Repo sync"
	}
} # syncTree

function wipeTree {
	echoStatus "Cleaning build directory"

	rm -rf ~/.ccache > /dev/null 2>&1 || { echo -e "${RED}Error removing ccache${NC}"; pbErrorMsg " " "Ccache removal"; }
	mka clean > /dev/null 2>&1 || { echo -e "${RED}Error making clean${NC}"; pbErrorMsg " " "Making Clean"; }
	if ls logs/*.log 1> /dev/null 2>&1; then
		rm logs/*.log
	fi
} # wipeEnv

function checkROMMake() {	
	if [ -e logs/ROM-$DATE.log ]; then
		if tail logs/ROM-$DATE.log | grep -q "make completed successfully"; then
			# Send alert
			pbSuccessMsg "ROM"

			if [[ $RELEASE == 1 ]]; then
				# Copy latest ota and target-files to repository
				echo -e "${GRE}Copying OTA and target-files to repository${NC}"
				cp `ls -t out/target/product/$DEVICE/Saber*.zip | head -1` $OUT_DIR
				cp `ls -t out/target/product/$DEVICE/obj/PACKAGING/target_files_intermediates/cm_$DEVICE*.zip | head -1` $TARGET_FILES_OUT_DIR
			fi
			exit 0
		fi
	fi
	pbErrorMsg "ROM" "Building"
	exit 1
} # checkROMMake

function buildROM {
	echoStatus "Starting ROM build"
	mka otapackage 2>&1 | tee logs/ROM-$DATE.log
} # buildROM

function packKernel {
	if [ -e $BOOT_IMG ]; then
		# zip up kernel
		if [[ -d $KERNEL_ZIP_DIR ]]; then
			cp $BOOT_IMG $KERNEL_ZIP_DIR
			cd $KERNEL_ZIP_DIR
			zip -r $OUT_DIR/SaberModCM12.1-$KERNEL_DATE-$DEVICE-Kernel.zip boot.img system/ kernel/ META-INF/
			pbSuccessMsg "Kernel"
			croot
		else
			echo -e "${RED}No kernel directory found!${NC}"
			pbErrorMsg "Kernel" "No kernel.zip source found"
		fi
	else
		echo "No boot.img"
	fi
} # packKernel

function buildKernel {
	# $1 - if we grab prebuilt or not
	
	case $1 in
		prebuilt)
			echoStatus "Packing prebuilt Kernel"
			;;
		*)
			echoStatus "Starting Kernel build"
			mka bootimage 2>&1 | tee logs/Kernel-$DATE.log
			
			# Pushbullet alert when build finishes
			if [ -e logs/Kernel-$DATE.log ]; then
				if tail Kernel-$DATE.log | grep -q "make completed successfully"; then
					pbSuccessMsg "Kernel"
				else
					pbErrorMsg "Kernel" "Building"
					exit 1
				fi
			fi
			;;
			
	esac

	packKernel
} # buildKernel

# Loop through arguments
for var in "$@"
do
	case "$var" in
		inc)
			INCREMENTAL=1;;
		kernel)
			KERNEL=1;;
		release)
			RELEASE=1;;
		rom)
			ROM=1;;
		odex)
			export WITH_DEXPREOPT := true;;
		prebuilt)
			PREBUILT=1;;
		sync)
			SYNC=1;;
		test )
			TEST=1;;
		wipe)
			WIPE=1;;
		*)
            		echo -e "${RED}Unknown parameter $var\n${NC}";;
	esac
done

if [[ $TEST == 1 ]]; then

	pbSuccessMsg
	exit 0
fi

# Begin build script
if [[ $KERNEL == 1 || $ROM == 1 || $SYNC == 1 || $WIPE == 1 ]]; then
	setEnv
else
	echo -e "${RED}Usage: $0 kernel rom sync wipe"
	echo "	inc - Build an incremental zip (needs target-files.zip in ~/ota.zip)"
	echo "	kernel - Build Kernel"
	echo "	rom - build ROM"
	echo "	sync - Sync repos"
	echo -e "	wipe - Clean build directory${NC}"
fi

if [[ $SYNC == 1 ]]; then
	syncTree
fi

if [[ $WIPE == 1 ]]; then 
	wipeTree
fi

if [[ $INCREMENTAL == 1 ]]; then
	export INCREMENTAL_BUILD=true
fi

if [[ $ROM == 1 ]]; then
	pbBeginMsg "ROM"
	buildROM
	checkROMMake
fi

if [[ $KERNEL == 1 || $PREBUILT == 1 ]]; then
	if [[ $PREBUILT == 1 || $ROM == 1 ]]; then
		buildKernel "prebuilt"
	else
		pbBeginMsg "Kernel"
		buildKernel
	fi
fi
