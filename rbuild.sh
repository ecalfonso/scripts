#!/bin/bash

# Initialize variables
DATE=$(date +"%Y%m%d-%T")
START=$(date +%s.%N)
STATUS="Initializing"

CLEAN=0
SYNC=0
WIPE=0
KERNEL=0

# Bash colors
RED='\033[0;31m'
GRE='\033[0;32m'
NC='\033[0m'

VARS=""

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
	kernel )
	    KERNEL=1;;
	jf )
	    DEVICE=jflte;;
	flo )
	    DEVICE=flo;;
	* )
            echo -e "${RED}Unknown parameter $var\n${NC}";;
    esac

    VARS="$VARS $var"
done

# Functions
function elapsed_time {
    if [ -z "$1" ]; then
        echo -e "${RED}elapsed_time requires start_time as a parameter${NC}";
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

# Announce begin of build
pb --note -t Starting ROM build for $DEVICE @ $DATE -m Flags: $VARS

# Setup build environment
. build/envsetup.sh || { echo -e "${RED}No build directory found${NC}"; exit 1; }

if [[ $SYNC == 1 ]]; then
    echo " "
    echo -e "${GRE}#########################################"
    echo "#"
    echo "# Repo sync"
    echo "#"
    echo -e "#########################################${NC}"
    echo " "
    STATUS="Repo sync"
    reposync || { echo -e "${RED}Error syncing repo${NC}"; pb_error_msg "$STATUS"; exit 1; }
fi

if [[ $WIPE == 0 && $CLEAN == 1 ]]; then
    echo " "
    echo -e "${GRE}#########################################"
    echo "#"
    echo "# Make installclean"
    echo "#"
    echo -e "#########################################${NC}"
    echo " "
    STATUS="Small wipe"
    mka installclean || { pb_error_msg "$STATUS"; exit 1; }
    if ls log*.out 1> /dev/null 2>&1; then
        rm log*.out
    fi
fi

if [[ $WIPE == 1 ]]; then
    echo " "
    echo -e "${GRE}#########################################"
    echo "#"
    echo "# Cleaning build directory"
    echo "#"
    echo -e "#########################################${NC}"
    echo " "
    STATUS="Full wipe"
    rm -rf ~/.ccache
    mka clean || { pb_error_msg "$STATUS"; exit 1; }
    mka clobber || { pb_error_msg "$STATUS"; exit 1; }
    if ls log*.out 1> /dev/null 2>&1; then
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
echo " "
echo -e "${GRE}#########################################"
echo "#"
echo "# Starting Kernel build for $DEVICE"
echo "#"
echo -e "#########################################${NC}"
echo " "
brunch cm_$DEVICE-userdebug 2>&1 | tee log-$DATE.out || { echo -e "${RED}Error during kernel build${NC}"; pb_error_msg "ROM Building" $generate_log $START; exit 1; }

if [[ $KERNEL == 1 ]]; then
    if [ -e kbuildv2.sh ]; then
	./kbuildv2.sh prebuilt jf
    fi
fi

# Pushbullet alert when build finishes
if [ -e log-$DATE.out ]; then
    if tail log-$DATE.out | grep -q "Package Complete"; then
        pb --note -t ROM complete for $DEVICE -m $(elapsed_time $START)
    fi
fi
