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
    successMsg
  else
    errorMsg
  fi
fi

