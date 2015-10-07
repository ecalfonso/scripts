#!/bin/bash

# Initialize variables
DATE=$(date +"%Y%m%d")
START=$(date +%s.%N)
STATUS="Initializing"

OUT_DIR='/home/ecalfonso/Android/Kernel'

CLEAN=0
SYNC=0
WIPE=0
PREBUILT=0

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
	prebuilt )
	    PREBUILT=1;;
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

    echo -e "Elapsed time: $HOUR hr $MIN min $SEC sec"
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
    pb --note -t Kernel build failed during $1 -m "$(elapsed_time $START)
$2"
}

# Default device is JFLTE if not specified
if [[ -z "$DEVICE" ]]; then
    DEVICE=jflte
fi

# Announce building
pb --note -t Starting Kernel build for $DEVICE @ $DATE -m Flags: $VARS

if [[ $PREBUILT == 0 ]]; then 

# Setup build environment
STATUS="Setting build env"
. build/envsetup.sh || { echo -e "${RED}No build directory found${NC}"; pb_error_msg "$STATUS"; exit 1; }

if [[ $SYNC == 1 ]]; then
    echo " "
    echo -e "${GRE}#########################################"
    echo "#"
    echo "# Repo sync"
    echo "#"
    echo -e "#########################################${NC}"
    echo " "
    STATUS="Repo sync"

    if [ -d vendor/sm ]; then
        reposync vendor/sm || { echo -e "${RED}Error syncing repo${NC}"; pb_error_msg "$STATUS"; exit 1; }
    fi

    if [[ $DEVICE == "jflte" ]]; then
        reposync device/samsung/jf-common || { echo -e "${RED}Error syncing repo${NC}"; pb_error_msg "$STATUS"; exit 1; }
        reposync kernel/samsung/jf || { echo -e "${RED}Error syncing repo${NC}"; pb_error_msg "$STATUS"; exit 1; }
    fi

    if [[ $DEVICE == "flo" ]]; then
        reposync device/asus/flo || { echo -e "${RED}Error syncing repo${NC}"; pb_error_msg "$STATUS"; exit 1; }
        reposync kernel/google/msm || { echo -e "${RED}Error syncing repo${NC}"; pb_error_msg "$STATUS"; exit 1; }
    fi
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
    mka installclean || { echo -e "${RED}Error @ mka installclean${NC}"; pb_error_msg "$STATUS"; exit 1; }
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
    mka clean || { echo -e "${RED}Error @ mka clean${NC}"; pb_error_msg "$STATUS"; exit 1; }
    mka clobber || { echo -e "${RED}Error @ mka clobber${NC}"; pb_error_msg "$STATUS"; exit 1; }
    if ls log*.out 1> /dev/null 2>&1; then
        rm log*.out
    fi
fi

# Set up CCACHE
export USE_CCACHE=1

# Start build
echo " "
echo -e "${GRE}#########################################"
echo "#"
echo "# Starting Kernel build for $DEVICE"
echo "#"
echo -e "#########################################${NC}"
echo " "
STATUS="Building"
lunch cm_$DEVICE-userdebug
mka bootimage 2>&1 | tee log-$DATE.out || { echo -e "${RED}Error during kernel build${NC}"; pb_error_msg "Kernel Building" $generate_log $START; exit 1; }

# Pushbullet alert when build finishes
if [ -e log-$DATE.out ]; then
    if tail log-$DATE.out | grep -q "Made boot image:"; then
	pb --note -t Kernel complete for $DEVICE -m $(elapsed_time $START)

        # zip up kernel
	if [[ -d ~/kernel/$DEVICE ]]; then
            cp ./out/target/product/$DEVICE/boot.img ~/kernel/$DEVICE/boot.img
            cd ~/kernel/$DEVICE
            zip -r $OUT_DIR/SaberModCM12.1-Kernel-$DEVICE-$DATE.zip META-INF/ kernel/ system/ boot.img
	else
	    echo -e "${RED}No kernel directory found!${NC}"
	    pb --note -t Kernel Complete for $DEVICE -m But no .zip directory found
	fi
    else
      pb_error_msg "$STATUS"; exit 1;
    fi
fi

else  # Zip up current boot.img without a rebuild
    if [ -e ./out/target/product/$DEVICE/boot.img ]; then
        # zip up kernel
        if [[ -d ~/kernel/$DEVICE ]]; then
            cp ./out/target/product/$DEVICE/boot.img ~/kernel/$DEVICE/boot.img
            cd ~/kernel/$DEVICE
            zip -r $OUT_DIR/SaberModCM12.1-Kernel-$DEVICE-$DATE.zip META-INF/ kernel/ boot.img
        else
            echo -e "${RED}No kernel directory found!${NC}"
            pb --note -t Kernel Complete for $DEVICE -m But no .zip directory found
        fi
    fi
fi
