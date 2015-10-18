#!/bin/bash

# Start up script to configure building essentials
#	If I ever lose what's on my machine, I save tons
#	of time running this rather than trying to remember
#	what I need to re-install

# Start at ~/
cd ~/

# Install packages for 32/64 bit CM12 building
sudo apt-get -y install bison build-essential curl flex git gnupg gperf libesd0-dev \
	liblz4-tool libncurses5-dev libsdl1.2-dev libwxgtk2.8-dev libxml2 libxml2-utils \
	lzop pngcrush schedtool squashfs-tools xsltproc zip zlib1g-dev
#	I exclude "openjdk-6-jdk openjdk-6-jre" from this list because I use Java7
	
# Packages for 64 bit CM12 building
sudo apt-get -y install g++-multilib gcc-multilib lib32ncurses5-dev lib32readline-gplv2-dev lib32z1-dev

# Packages for building with LZMA compression
sudo apt-get -y install python-dev liblzma-dev

# Packages for SaberMod toolchains - NOT REQUIRED FOR BUILDING CM
sudo apt-get -y install libcap-dev texinfo automake autoconf libgmp-dev libexpat-dev \
	python-dev build-essential gcc-multilib g++-multilib libncurses5-dev flex bison libtool gawk;

# My custom packages I need
sudo apt-get -y install openssh-server git tmux curl openjdk-7-jdk vim

# Create personal bin directory
mkdir ~/.bin
# Get repo command
curl https://storage.googleapis.com/git-repo-downloads/repo > ~/.bin/repo
# Set permissions
chmod a+x ~/.bin/repo

# Configure Github
# https://help.github.com/articles/generating-ssh-keys/
git config --global user.email xsynergy510x@gmail.com
git config --global user.name "Eduard Alfonso"
git config --global push.default simple

# Set up Github repos
mkdir ~/github
cd ~/github

# Grab my CM forks and set proper upstream
for repo in \
	android_art \
	android_bionic \
	android_build \
	android_device_samsung_jflte \
	android_device_samsung_jf-common \
	android_external_chromium_org \
	android_external_libpng \
	android_frameworks_base \
	android_hardware_qcom_display \
	android_kernel_samsung_jf \
	android_libcore \
	android_packages_apps_Dialer \
	android_packages_apps_Mms-caf \
	android_packages_apps_Settings \
	android_system_core \
	android_vendor_cm
	do
		git clone git@github.com:xsynergy510x/$repo
		cd $repo
		git remote add upstream https://github.com/CyanogenMod/$repo
		cd ..
	done
# Grab other repos
for repo in \
	scripts	\
	roomservice \
	android_vendor_sabermod \
	proprietary_vendor_samsung
	do
		git clone git@github.com:xsynergy510x/$repo
	done

# Download backports.lzma
mkdir -p ~/Downloads
cd ~/Downloads
git clone git://github.com/peterjc/backports.lzma.git
cd backports.lzma
sudo python setup.py install
cd test
python test_lzma.py

#
# Add my custom paths to ~/.bashrc
#

# Use CCACHE
echo "export USE_CCACHE=1" >> ~/.bashrc
export ANDROID_CCACHE_DIR="$HOME/.ccache"
export ANDROID_CCACHE_SIZE="50G"

# Set up custom bin directory
echo "export PATH=~/.bin:$PATH" >> ~/.bashrc

# Set up CM lzma compression variable
# https://github.com/CyanogenMod/android_build/commit/e78b239cbe782454d6df0916dc51bbf35ede5572
echo "export WITH_LZMA_OTA=TRUE" >> ~/.bashrc

# Reload .bashrc
source ~/.bashrc

# Create my build directory
mkdir ~/cm12
cd ~/cm12
repo init -u https://github.com/CyanogenMod/android.git -b cm-12.1
~/github/android_build/envsetup.sh .
repo sync || exit 1
# Add my roomservice
mkdir -p ~/cm12/.repo/local_manifests/
cp ~/github/roomservice/*.xml ~/cm12/.repo/local_manifests/
# Set build environment and reposync
source build/envsetup.sh
reposync
breakfast cm_jflte-userdebug
lunch cm_jflte-userdebug
