#!/bin/bash

# Initialize variables
DATE=$(date +"%Y%m%d")
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
STATUS="Setting build env"
. build/envsetup.sh || { echo "No build directory found"; pb_error_msg "$STATUS"; exit 1; }

if [[ $SYNC == 1 ]]; then
    echo "Repo sync"
    STATUS="Repo sync"

    if [ -d vendor/sm ]; then
        reposync vendor/sm || { echo "Error syncing repo"; pb_error_msg "$STATUS"; exit 1; }
    fi

    if [[ $DEVICE == "jflte" ]]; then
        reposync device/samsung/jf-common || { echo "Error syncing repo"; pb_error_msg "$STATUS"; exit 1; }
        reposync kernel/samsung/jf || { echo "Error syncing repo"; pb_error_msg "$STATUS"; exit 1; }
    fi

    if [[ $DEVICE == "flo" ]]; then
        reposync device/asus/flo || { echo "Error syncing repo"; pb_error_msg "$STATUS"; exit 1; }
        reposync kernel/google/msm || { echo "Error syncing repo"; pb_error_msg "$STATUS"; exit 1; }
    fi
fi

if [[ $WIPE == 0 && $CLEAN == 1 ]]; then
    echo "Make installclean"
    STATUS="Small wipe"
    mka installclean || { echo "Error @ mka installclean"; pb_error_msg "$STATUS"; exit 1; }
    if [ -e log*.out ]; then
        rm log*.out
    fi
fi

if [[ $WIPE == 1 ]]; then
    echo "Cleaning build directory"
    STATUS="Full wipe"
    rm -rf ~/.ccache
    mka clean || { echo "Error @ mka clean"; pb_error_msg "$STATUS"; exit 1; }
    mka clobber || { echo "Error @ mka clobber"; pb_error_msg "$STATUS"; exit 1; }
    if [ -e log*.out ]; then
        rm log*.out
    fi
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
echo "Starting Kernel build for $DEVICE"
pb --note -t Starting Kernel build for $DEVICE @ $DATE
mka bootimage 2>&1 | tee log-$DATE.out || { echo "Error during kernel build"; pb_error_msg "Kernel Building" $generate_log $START; exit 1; }

# Pushbullet alert when build finishes
if [ -e log-$DATE.out ]; then
    if tail log-$DATE.out | grep -q "Made boot image:"; then
        pb --note -t Kernel complete for $DEVICE -m Elapsed time: $MIN min $SEC sec

        # zip up kernel
	if [[ -d ~/kernel/$DEVICE ]]; then
            cp ./out/target/product/$DEVICE/boot.img ~/kernel/$DEVICE/boot.img
            cd ~/kernel/$DEVICE
            zip -r SaberModCM12.1-Kernel-$DEVICE-$DATE.zip META-INF/ kernel/ boot.img
	else
	    echo "No kernel directory found!"
	    pb --note -t Kernel Complete for $DEVICE -m But no .zip directory found
	fi
    fi
fi
