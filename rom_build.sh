#!/bin/bash

# Set device
DEVICE=jflte
DATE=$(date +"%Y%m%d-%T")

CLEAN=0
REMOTE=0
SYNC=0

for var in "$@"
do
    case "$var" in
        clean )
            CLEAN=1
            ;;
        remote )
            REMOTE=1
            ;;
        sync )
            SYNC=1
            ;;
    esac
done

if [[ $SYNC == 1 ]]; then
    echo "Repo sync"
    repo sync
fi

if [[ $CLEAN == 1 ]]; then
    echo "Cleaning build directory"
    rm -rf ~/.ccache
    make clean
    make clobber
fi

# Setup build environment
. build/envsetup.sh
export BUILDING_RECOVERY=false
lunch "cm_$DEVICE-userdebug"

# Start build
START=$(date +%s.%N)
make installclean
echo "Starting build for $DEVICE"
pb --note -t Starting build for $DEVICE @ $DATE
brunch $DEVICE 2>&1 | tee log-$DATE.out
END=$(date +%s.%N)
MIN=$(echo "($END-$START)/60"|bc)
SEC=$(echo "($END-$START)"|bc)

# Pushbullet alert when build finishes
if [ -e log-$DATE.out ]; then
    if tail log-$DATE.out | grep -q "Package Complete"; then
        pb --note -t Package complete for $DEVICE -m Elapsed time: $MIN min $SEC sec
        if [[ $REMOTE == 1 ]]; then
            echo "Sending zip to Drive"
            cp out/target/product/jflte/Op*.zip ~/ext_storage/Drive/ROMs/
            cd ~/ext_storage/Drive
            grive
            cd ~/jflte
        fi
    else
        pb --note -t Build failed for $DEVICE -m Elapsed time: $MIN min $SEC sec 
    fi
fi
