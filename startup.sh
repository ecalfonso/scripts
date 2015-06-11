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

# Packages for SaberMod toolchains
sudo apt-get -y install libcap-dev texinfo automake autoconf libgmp-dev libexpat-dev \
	python-dev build-essential gcc-multilib g++-multilib libncurses5-dev flex bison libtool gawk;

# My custom packages
sudo apt-get -y install openssh-server git tmux curl openjdk-7-jdk vim

# Create personal bin directory
mkdir ~/.bin
# Get repo command
curl https://storage.googleapis.com/git-repo-downloads/repo > ~/.bin/repo
# Create custom fetch-merge-push command
echo "git fetch upstream/cm-12.1; git merge upstream/cm-12.1; git push" > ~/.bin/fmp
# Set permissions
chmod a+x ~/.bin/repo
chmod u+x ~/.bin/fmp

# Set up Github repos
mkdir ~/github
cd ~/github

# Grab my CM forks and set proper upstream
for repo in \
	android_build \
	android_device_asus_flo \
	android_device_samsung_jf-common \
	android_device_samsung_jflte \
	android_device_samsung_qcom-common \
	android_external_chromium_org \
	android_external_libpng \
	android_frameworks_base \
	android_hardware_qcom_display \
	android_kernel_google_msm \
	android_kernel_samsung_jf \
	android_libcore \
	android_packages_apps_Dialer \
	android_packages_apps_Mms-caf \
	android_packages_apps_Settings \
	android_system_core \
	android_vendor_cm \
	android_vendor_sabermod
	do
		git clone git@github.com:xsynergy510x/$repo
		cd $repo
		git remote add upstream https://github.com/CyanogenMod/$repo
		cd ..
	done
# Grab other repos
for repo in \
	roomservice \
	scripts	\
	proprietary_vendor_samsung
	do
		git clone git@github.com:xsynergy510x/$repo
	done

# Add my custom paths to ~/.bashrc
echo "export USE_CCACHE=1" >> ~/.bashrc

# Set up custom bin directory
echo "export PATH=~/.bin:$PATH" >> ~/.bashrc
export PATH=~/.bin:$PATH

# Create my build directory
mkdir ~/cm
cd ~/cm
repo init -u https://github.com/CyanogenMod/android.git -b cm-12.1
# Add my roomservice
mkdir -p ~/cm/.repo/local_manifests/
cp ~/github/roomservice/roomservice.xml ~/cm/.repo/local_manifests/
# Set build environment and reposync
. build/envsetup.sh
reposync
