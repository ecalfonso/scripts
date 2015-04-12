#!/bin/bash

# Set device
DATE=$(date +"%Y%m%d-%T")

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

if [[ $SYNC == 1 ]]; then
    echo "Repo sync"
    repo sync device/samsung/jf-common
    repo sync device/asus/flo
    repo sync kernel/samsung/jf
    repo sync kernel/google/msm
fi

if [[ $CLEAN == 1 ]]; then
    echo "Fully wiping"
    rm -rf ~/.ccache
    rm log*.out
    make clobber
    WIPE=0
fi

if [[ $WIPE == 1 ]]; then
    echo "Cleaning build directory"
    make installclean
fi

# Set up CCACHE
export USE_CCACHE=1

# Setup build environment
. build/envsetup.sh

# Remove old build.prop
if [ -e out/target/product/$DEVICE/system/build.prop ]; then
    echo "Removing old build.prop"
    rm out/target/product/$DEVICE/system/build.prop
fi

# Start build
START=$(date +%s.%N)
echo "Starting build for $DEVICE"
pb --note -t Starting Kernel build for $DEVICE @ $DATE
breakfast cm_$DEVICE-userdebug
mka bootimage 2>&1 | tee log-$DATE.out
END=$(date +%s.%N)
MIN=$(echo "($END-$START)/60"|bc)
SEC=$(echo "($END-$START)%60"|bc)

# Pushbullet alert when build finishes
if [ -e log-$DATE.out ]; then
    if tail log-$DATE.out | grep -q "Made boot image:"; then
        pb --note -t Kernel complete for $DEVICE -m Elapsed time: $MIN min $SEC sec

        # zip up kernel
        cp ./out/target/product/$DEVICE/boot.img ~/kernel/boot.img
        cd ~/kernel/
        zip -r SaberModCM12.1-kernel-$DEVICE-$DATE.zip META-INF/ kernel/ system/ boot.img
    else
	LOG=$(grep error\: log-$DATE.out)
        pb --note -t Kernel build failed for $DEVICE -m "Elapsed time: $MIN min $SEC sec\n $LOG" 
    fi
fi
