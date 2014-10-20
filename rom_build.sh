#!/bin/bash

# Clean the build directory
if [[ $1 == "clean" ]]; then
  echo "Cleaning before building"
  echo "Removed ccache..."
  rm -rf ~/.ccache
  echo "Making Clean..."
  make clean
  echo "Making Clobber..."
  make clobber
fi	

# Set the start time
DATE=$(date +"%Y%m%d-%T")
#PB_KEY=fece533b53cce221dfb46538c68a992b

# Set the device
DEVICE=jflte

# Set complete and error messages
# These use custom pushbullet commands
initialMsg() {
	$(pb --note -t Build starting for $DEVICE -m Build-$DATE)
}

successMsg() {
	$(pb --note -t Package Complete for $DEVICE -m Build-$DATE)
}

errorMsg() {
	$(pb --note -t Build failed for $DEVICE -m Build-$DATE)
}

# Remove old build.prop to generate a new one
if [ -e out/target/product/$DEVICE/system/build.prop ]; then
  echo "Removing old build.prop"
  rm out/target/product/$DEVICE/system/build.prop
fi

echo "Sending start time to devices via PushBullet...."
initialMsg

# Begin the build
echo "Starting log-$DATE.out"
. build/envsetup.sh
croot
brunch $DEVICE 2>&1 | tee log-$DATE.out
# Set end time
END_DATE=$(date +"%Y%m%d-%T")

# Alert me when build completes
echo "Alerting devices that building has stopped via PushBullet..."
if [ -e log-$DATE.out ]; then
  if tail log-$DATE.out | grep -q "Package Complete"; then
    #PB_MSG="Package complete"
    successMsg
  else
    #PB_MSG="Build failed"   
    errorMsg
  fi
fi

#curl -u $PB_KEY: https://api.pushbullet.com/v2/pushes -d type=note -d title="$PB_MSG for $DEVICE" -d body="build-$DATE stopped at $END_DATE" > /dev/null 2>&1
