#!/bin/bash

#
# Set up Static IP
#
head -n -3 /etc/network/interfaces > tmp

ETH=`ifconfig -a | grep eth | cut -d " " -f 1`
sudo echo "auto $ETH" >> tmp
sudo echo "iface $ETH inet static" >> tmp
sudo echo "address 192.168.0.232" >> tmp
sudo echo "netmask 255.255.255.0" >> tmp
sudo echo "gateway 192.168.0.1" >> tmp
sudo echo "dns-nameservers 8.8.8.8 4.4.4.4" >> tmp

sudo mv tmp /etc/network/interfaces

#
# Install Packages
#

# Install packages for CyanogenMod Building
# https://wiki.cyanogenmod.org/w/Build_for_jfltexx
sudo apt-get install -y --fix-missing bison build-essential curl flex git gnupg gperf libesd0-dev \
	liblz4-tool libncurses5-dev libsdl1.2-dev libwxgtk2.8-dev libxml2 libxml2-utils \
	lzop pngcrush schedtool squashfs-tools xsltproc zip zlib1g-dev
sudo apt-get install -y --fix-missing g++-multilib gcc-multilib lib32ncurses5-dev lib32readline-gplv2-dev lib32z1-dev

# Packages for building with LZMA compression
sudo apt-get install -y --fix-missing python-dev liblzma-dev

# Packages I need to have
sudo apt-get install -y --fix-missing openssh-server git tmux curl openjdk-7-jdk vim

#
# Setting up my directories
#

# Create my own .bin directory
mkdir -p ~/.bin && curl https://storage.googleapis.com/git-repo-downloads/repo > ~/.bin/repo && chmod a+x ~/.bin/repo || exit 1

# Add .bin to $PATH
if ! grep -q "~/.bin" ~/.bashrc; then
	echo 'PATH="~/.bin:$PATH"' >> ~/.bashrc
fi

# Configure Github
# https://help.github.com/articles/generating-ssh-keys/
# https://help.github.com/articles/adding-a-new-ssh-key-to-your-github-account/
git config --global user.email xsynergy510x@gmail.com
git config --global user.name "Eduard Alfonso"
git config --global push.default simple

# Set up Github repos
mkdir -p ~/github

# Get my Github repos
cd ~/github && for repo in \
	android_art \
	android_bionic \
	android_build \
	android_device_samsung_jf-common \
	android_external_wpa_supplicant_8 \
	android_frameworks_av \
	android_frameworks_base \
	android_kernel_samsung_jf \
	android_packages_apps_Bluetooth \
	android_packages_apps_Settings \
	android_system_bt \
	android_vendor_cm
	do
		if [ ! -d $repo ]; then
			git clone git@github.com:xsynergy510x/$repo
			cd $repo && git remote add upstream https://github.com/CyanogenMod/$repo
			cd ..
		fi
	done

# Grab other repos
cd ~/github && for repo in \
	scripts	\
	roomservice \
	android_device_samsung_jfltecdma \
        android_device_samsung_jfltegsm
	do
		if [ ! -d ~/github/$repo ]; then
			git clone git@github.com:xsynergy510x/$repo
		fi
	done

# Download backports.lzma
mkdir -p ~/Downloads
cd ~/Downloads && git clone git://github.com/peterjc/backports.lzma.git
cd backports.lzma && sudo python setup.py install
cd test && python test_lzma.py

# Set up CM directory
CM_DIR=~/cm13
CM_BRANCH=cm-13.0

mkdir -p $CM_DIR
cd $CM_DIR && repo init -u https://github.com/CyanogenMod/android.git -b $CM_BRANCH
repo sync

# Add CM specific .bashrc variables
if ! grep -q "USE_CCACHE" ~/.bashrc; then
        echo 'export USE_CCACHE=1' >> ~/.bashrc
fi

if ! grep -q "ANDROID_CCACHE_DIR" ~/.bashrc; then
        echo "export ANDROID_CCACHE_DIR=\"$CM_DIR/.ccache\"" >> ~/.bashrc
fi

if ! grep -q "ANDROID_CCACHE_SIZE" ~/.bashrc; then
        echo 'export ANDROID_CCACHE_SIZE="100G"' >> ~/.bashrc
fi

#
# Set up local http site
#
sudo apt-get install -y apache2
sudo rm /var/www/html/index.html
sudo ln -s ~/Android/ /var/www/html/Android
