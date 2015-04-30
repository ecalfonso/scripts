#!/bin/bash

# Set device
DATE=$(date +"%Y%m%d")

CLEAN=0
SYNC=0
WIPE=0

for var in "$@"
do
    case "$var" in
        clean )
            CLEAN=1;;
        sync )
            SYNC=1;;
	wipe )
	    WIPE=1;;
	jf )
	    DEVICE=jflte;;
	flo )
	    DEVICE=flo;;
    esac
done

# Setup build environment
. build/envsetup.sh

if [[ -z "$DEVICE" ]]; then
    DEVICE=jflte
fi

if [[ $SYNC == 1 ]]; then
    echo "Repo sync"
    if [[ $DEVICE == "jflte" ]]; then
        repo sync device/samsung/jf-common
        repo sync kernel/samsung/jf
    fi
    if [[ $DEVICE == "flo" ]]; then
        repo sync device/asus/flo
        repo sync kernel/google/msm
    fi
fi

if [[ $CLEAN == 1 ]]; then
    echo "Fully wiping"
    rm -rf ~/.ccache
    rm log*.out
    mka clobber
    WIPE=0
fi

if [[ $WIPE == 1 ]]; then
    echo "Cleaning build directory"
    mka installclean
fi

# Set up CCACHE
export USE_CCACHE=1

# Remove old build.prop
if [ -e out/target/product/$DEVICE/system/build.prop ]; then
    rm out/target/product/$DEVICE/system/build.prop
fi

# Start build
START=$(date +%s.%N)
echo "Starting build for $DEVICE"
pb --note -t Starting Kernel build for $DEVICE @ $DATE
lunch cm_$DEVICE-userdebug
mka bootimage 2>&1 | tee log-$DATE.out
END=$(date +%s.%N)
MIN=$(echo "($END-$START)/60"|bc)
SEC=$(echo "($END-$START)%60"|bc)

# Pushbullet alert when build finishes
if [ -e log-$DATE.out ]; then
    if tail log-$DATE.out | grep -q "Made boot image:"; then
        pb --note -t Kernel complete for $DEVICE -m Elapsed time: $MIN min $SEC sec

        # zip up kernel
	if [[ -d ~/kernel/$DEVICE ]]; then
            cp ./out/target/product/$DEVICE/boot.img ~/kernel/$DEVICE/boot.img
            cd ~/kernel/$DEVICE
            zip -r SaberModCM12.1-kernel-$DEVICE-$DATE.zip META-INF/ kernel/ system/ boot.img
	else
	    pb --note -t Kernel Complete for $DEVICE -m But no .zip directory found
	fi
    else
	LOG=$(grep error\: log-$DATE.out)
	# Check if LOG is empty, there might be a forbidden warning
	if [ -z "$LOG" ]; then
	    LOG=$(grep forbidden warning\: log-$DATE.out)
	fi
        pb --note -t Kernel build failed for $DEVICE -m "Elapsed time: $MIN min $SEC sec
$LOG" 
    fi
fi
