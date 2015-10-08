#!/bin/bash

# Set time
DATE=$(date +"%Y%m%d-%T")
KERNEL_DATE=$(date +"%Y%m%d")
START=$(date +%s.%N)

# Initialize build variables
DEVICE=jflte
KERNEL=0	# Set to 1 to build kernel
ROM=0		# Set to 1 to Build ROM
SYNC=0		# Sync source
WIPE=0		# Fully wipe before build

# File/Directory variables
BOOT_IMG='out/target/product/$DEVICE/boot.img'
KERNEL_ZIP_FILES='kernel/samsung/jf/zip/'
OUT_DIR='/home/ecalfonso/Android/'

# Bash colors
RED='\033[0;31m'; GRE='\033[0;32m'; NC='\033[0m'

# Functions
function echoStatus() { 
	# $1 - What to echo

	echo " "
    echo -e "${GRE}#########################################"
    echo "#"
    echo "# $1"
    echo "#"
    echo -e "#########################################${NC}"
    echo " "
} # echoStatus()

function elapsedTime() {
    END=$(date +%s.%N)
    HOUR=$(echo "(($END-$START)/3600)"|bc)
    MIN=$(echo "(($END-$START)/60)%60"|bc)
    SEC=$(echo "($END-$START)%60"|bc)

    echo "Elapsed time: $HOUR hr $MIN min $SEC sec"
} # elapsedTime

function pbBeginMsg() {
	# $1 - Build variant
	
	pb --note -t Starting $1 build for $DEVICE @ $DATE
} # pbBeginMsg()

function pbErrorMsg() {
	# $1 - Build variant
	# $2 - Where the build failed
	
	pb --note -t $1 build failed during $2 for $DEVICE -m \
	Flags: $VARS \
	elapsedTime()
	
	exit 1
} # pbErrorMsg()

function pbSuccessMsg() {
	# $1 - Build variant
	
	pb --note -t $1 build complete for $DEVICE -m elapsedTime()
} # pbSuccessMsg()

function setEnv() {
	echoStatus "Setting Environment"

	if [ ! -f build/envsetup.sh ];
	then
		echo -e "${RED}Error setting up environment${NC}";
		pbErrorMsg() " " "Environment setup"
	fi

	. build/envsetup.sh >/dev/null 2>&1
	lunch cm_$DEVICE-userdebug >/dev/null 2>&1
} # setEnv()

function syncTree() {
	echoStatus "Syncing repos"

	reposync || {
		echo -e "${RED}Error syncing repo${NC}"
		pbErrorMsg() " " "Repo sync"
	}
} # syncTree()

function wipeTree() {
	echoStatus "Cleaning build directory"

	rm -rf ~/.ccache || {echo -e "${RED}Error removing ccache${NC}"; pbErrorMsg() " " "Ccache removal" }
    mka clean || { echo -e "${RED}Error making clean${NC}"; pbErrorMsg() " " "Making Clean" }
    if ls log*.out 1> /dev/null 2>&1; then
        rm log*.out
    fi
} # wipeEnv()

function buildROM() {
	echoStatus "Starting ROM build"
	mka otapackage 2>&1 | tee ROM-$DATE.log
	
	if [ -e ROM-$DATE.log ]; then
		if tail ROM-$DATE.log | grep -q "Package Complete"; then
			pbSuccessMsg() "ROM"
		else
			pbErrorMsg() "ROM" "Building"
		fi
	fi
} # buildROM()

function packKernel() {
	if [ -e $BOOT_IMG ]; then
		# zip up kernel
		if [[ -d $KERNEL_ZIP_FILES ]]; then
			zip -r $OUT_DIR/SaberModCM12.1-$KERNEL_DATE-$DEVICE-Kernel.zip $BOOT_IMG $KERNEL_ZIP_FILES/*
			pbSuccessMsg() "Kernel"
		else
			echo -e "${RED}No kernel directory found!${NC}"
			pbErrorMsg() "Kernel" "No kernel.zip source found"
		fi
	fi
} # packKernel()

function buildKernel() {
	# $1 - if we grab prebuilt or not
	
	case $1 in
		prebuilt)
			echoStatus "Packing prebuilt Kernel"
			;;
		*)
			echoStatus "Starting Kernel build"
			mka bootimage 2>&1 | tee Kernel-$DATE.log
			
			# Pushbullet alert when build finishes
			if [ -e Kernel-$DATE.log ]; then
				if tail Kernel-$DATE.log | grep -q "Made boot image:"; then
					pbSuccessMsg() "Kernel"
				else
					pbErrorMsg() "Kernel" "Building"
				fi
			fi
			;;
			
		packKernel()
	esac
	
	
} # buildKernel()

# Loop through arguments
for var in "$@"
do
    case "$var" in
        kernel)
            KERNEL=1;;
        rom)
            ROM=1;;
		sync)
			SYNC=1;;
		wipe)
			WIPE=1;;
		*)
            echo -e "${RED}Unknown parameter $var\n${NC}";;
    esac
done

# Begin build script
setEnv()
if [[ $SYNC == 1 ]]; then syncTree()
if [[ $WIPE == 1 ]]; then wipeTree()
if [[ $ROM == 1 ]]; then
	pbBeginMsg() "ROM"
	buildROM()
fi
if [[ $KERNEL == 1 ]]; then
	pbBeginMsg() "Kernel"
	if [[ $ROM == 1 ]]; then
		buildKernel() "prebuilt"
	else
		buildKernel()
	fi
fi

# Done
