#!/bin/bash

if [ ! -e ~/jflte/out/target/product/jflte/system/build.prop ]; then
    echo "No build.prop to parse, abort"
    exit 1
fi

BUILD=$(grep ro.modversion ~/jflte/out/target/product/jflte/system/build.prop | cut -d "=" -f2 )
echo "Current build is $BUILD"

if [ ! -e ~/jflte/out/target/product/jflte/$Build.zip ]; then
    echo "Build $BUILD.zip doesn't exist, abort"
    exit 1
fi
