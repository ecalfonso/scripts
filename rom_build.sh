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
        wipe )
            WIPE=1;;
        sync )
            SYNC=1;;
	jf )
	    DEVICE=jflte;;
	flo )
	    DEVICE=flo;;
    esac
done

if [[ $SYNC == 1 ]]; then
    echo "Repo sync"
    repo sync
fi

if [[ $CLEAN == 1 ]]; then
    echo "Make installclean"
    make installclean
fi

if [[ $WIPE == 1 ]]; then
    echo "Cleaning build directory"
    rm -rf ~/.ccache
    make clean
    make clobber
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
pb --note -t Starting ROM build for $DEVICE @ $DATE
brunch cm_$DEVICE-userdebug 2>&1 | tee log-$DATE.out
END=$(date +%s.%N)
HOUR=$(echo "(($END-$START)/3600)"|bc)
MIN=$(echo "(($END-$START)/60)%60"|bc)
SEC=$(echo "($END-$START)%60"|bc)

# Pushbullet alert when build finishes
if [ -e log-$DATE.out ]; then
    if tail log-$DATE.out | grep -q "Package Complete"; then
        pb --note -t ROM complete for $DEVICE -m Elapsed time: $HOUR hr $MIN min $SEC sec
    else
	LOG=$(grep error\: log-$DATE.out)
        pb --note -t ROM build failed for $DEVICE -m "Elapsed time: $HOUR hr $MIN min $SEC sec\n $LOG"
    fi
fi
