#!/bin/bash

# Start up script to configure building essentials
#	If I ever lose what's on my machine, I save tons
#	of time running this rather than trying to remember
#	what I need to re-install

# Start at ~/
cd ~/

# Install packages
sudo apt-get -y install bison build-essential curl flex git gnupg gperf libesd0-dev liblz4-tool libncurses5-dev libsdl1.2-dev libwxgtk2.8-dev libxml2 libxml2-utils lzop openjdk-6-jdk openjdk-6-jre pngcrush schedtool squashfs-tools xsltproc zip zlib1g-dev \
	g++-multilib gcc-multilib lib32ncurses5-dev lib32readline-gplv2-dev lib32z1-dev \
	openssh-server git tmux curl openjdk-7-jdk vim

# Create personal bin directory
mkdir ~/.bin
curl https://storage.googleapis.com/git-repo-downloads/repo > ~/.bin/repo
echo "git fetch upstream; git merge upstream/cm-12.0; git push" > ~/.bin/fmp
chmod a+x ~/.bin/repo
chmod u+x ~/.bin/fmp

# Make system configs
echo "vm.swappiness=80" >> /etc/sysctl.conf 

# Set up Github repos
mkdir ~/github
cd ~/github
for repo in \
	android_build \
	android_device_samsung_jf-common \
	android_device_samsung_jflte \
	android_device_samsung_qcom-common \
	android_frameworks_base \
	android_kernel_samsung_jf \
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

# Add my custom paths to ~/.bashrc
echo "export USE_CCACHE=1" >> ~/.bashrc

# Set up custom bin directory
echo "export PATH=~/.bin:$PATH" >> ~/.bashrc
export PATH=~/.bin:$PATH

# Create my build directory
mkdir ~/cm12
cd ~/cm12
repo init -u https://github.com/CyanogenMod/android.git -b cm-12.0
repo sync
prebuilts/misc/linux-x86/ccache/ccache -M 50G
