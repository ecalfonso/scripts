#!/bin/bash

# Initialize variables
DATE=$(date +"%Y%m%d-%T")
START=$(date +%s.%N)
STATUS="Initializing"

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

# Functions
function elapsed_time {
    if [ -z "$1" ]; then
        echo "elapsed_time requires start_time as a parameter";
        exit 1;
    fi

    END=$(date +%s.%N)
    HOUR=$(echo "(($END-$1)/3600)"|bc)
    MIN=$(echo "(($END-$1)/60)%60"|bc)
    SEC=$(echo "($END-$1)%60"|bc)

    echo "Elapsed time: $HOUR hr $MIN min $SEC sec"
}

function generate_log {
    if [ -e log-$DATE.out ]; then
	LOG=$(grep error\: log-$DATE.out)
	# Check if LOG is empty, there might be a forbidden warning
        if [ -z "$LOG" ]; then
            LOG=$(grep forbidden warning\: log-$DATE.out)
        fi
    fi
    echo $LOG
}

function pb_error_msg {
    pb --note -t ROM build failed during $1 -m "$(elapsed_time $START)
$2"
}

# Setup build environment
. build/envsetup.sh || { echo "No build directory found"; exit 1; }

if [[ $SYNC == 1 ]]; then
    echo "Repo sync"
    STATUS="Repo sync"
    reposync || { pb_error_msg "$STATUS"; exit 1; }
fi

if [[ $WIPE == 0 && $CLEAN == 1 ]]; then
    echo "Make installclean"
    STATUS="Small wipe"
    mka installclean || { pb_error_msg "$STATUS"; exit 1; }
    if [ -e log*.out ]; then
        rm log*.out
    fi
fi

if [[ $WIPE == 1 ]]; then
    echo "Cleaning build directory"
    STATUS="Full wipe"
    rm -rf ~/.ccache
    mka clean || { pb_error_msg "$STATUS"; exit 1; }
    mka clobber || { pb_error_msg "$STATUS"; exit 1; }
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
echo "Starting build for $DEVICE"
pb --note -t Starting ROM build for $DEVICE @ $DATE
brunch cm_$DEVICE-userdebug 2>&1 | tee log-$DATE.out || { pb_error_msg "ROM Building" $generate_log $START; exit 1; }

# Pushbullet alert when build finishes
if [ -e log-$DATE.out ]; then
    if tail log-$DATE.out | grep -q "Package Complete"; then
        pb --note -t ROM complete for $DEVICE -m $(elapsed_time $START)
    fi
fi
