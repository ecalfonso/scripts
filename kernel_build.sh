#!/bin/bash

# Set device
DEVICE=jfltetmo
DATE=$(date +"%Y%m%d-%T")

CLEAN=0
SYNC=0

for var in "$@"
do
    case "$var" in
        clean )
            CLEAN=1
            ;;
        sync )
            SYNC=1
            ;;
    esac
done

if [[ $SYNC == 1 ]]; then
    echo "Repo sync"
    repo sync device/samsung/jf-common
    repo sync kernel/samsung/jf
fi

if [[ $CLEAN == 1 ]]; then
    echo "Cleaning build directory"
    rm -rf ~/.ccache
    rm log*.out
    make clean
    make clobber
fi

# Setup build environment
. build/envsetup.sh

# Don't build recovery
export BUILDING_RECOVERY=false

# Enable -O3 flags
export USE_O3_OPTIMIZATIONS=true

# Remove old build.prop
if [ -e out/target/product/$DEVICE/system/build.prop ]; then
    echo "Removing old build.prop"
    rm out/target/product/$DEVICE/system/build.prop
fi

# Start build
START=$(date +%s.%N)
echo "Starting build for $DEVICE"
pb --note -t Starting Kernel build for $DEVICE @ $DATE
breakfast $DEVICE
mka bootimage 2>&1 | tee log-$DATE.out
END=$(date +%s.%N)
MIN=$(echo "($END-$START)/60"|bc)
SEC=$(echo "($END-$START)%60"|bc)

# Pushbullet alert when build finishes
if [ -e log-$DATE.out ]; then
    if tail log-$DATE.out | grep -q "Made boot image:"; then
        pb --note -t Kernel complete for $DEVICE -m Elapsed time: $MIN min $SEC sec
    else
        pb --note -t Kernel build failed for $DEVICE -m Elapsed time: $MIN min $SEC sec 
    fi
fi
