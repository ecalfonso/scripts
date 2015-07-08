#!/bin/bash

# Set variables
DATE=$(date +"%Y%m%d-%T")
CLEAN=0
SYNC=0
WIPE=0

# Loop through script arguments
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

# Setup build environment
. build/envsetup.sh

if [[ $SYNC == 1 ]]; then
    echo "Repo sync"
    reposync
fi

if [[ $CLEAN == 1 ]]; then
    echo "Make installclean"
    mka installclean
    rm log*.out
fi

if [[ $WIPE == 1 ]]; then
    echo "Cleaning build directory"
    rm -rf ~/.ccache
    mka clean
    mka clobber
fi

# Default device is JFLTE if not specified
if [[ -z "$DEVICE" ]]; then
    DEVICE=jflte
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
	# Check if LOG is empty, there might be a forbidden warning
        if [ -z "$LOG" ]; then
            LOG=$(grep forbidden warning\: log-$DATE.out)
        fi
        pb --note -t ROM build failed for $DEVICE -m "Elapsed time: $HOUR hr $MIN min $SEC sec
$LOG"
    fi
fi
