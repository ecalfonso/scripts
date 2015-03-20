#!/bin/bash

# Start up script to configure building essentials
#	If I ever lose what's on my machine, I save tons
#	of time running this rather than trying to remember
#	what I need to re-install

# Start at ~/
#cd ~/

# Install packages
#sudo apt-get -y install \
#	openssh-server \
#	git \
#	tmux \
#	curl \
#	openjdk-7-jdk \
#	vim
	
# Make system configs
#echo "vm.swappiness=80" >> /etc/sysctl.conf 

# Set up Github repos
REPOS="
	android_build
	roomservice
	scripts"
	
mkdir ~/github
cd ~/github
for i in $REPOS
	do
		git clone https://github.com/xsynergy510x/"$i".git
	done

# Add my custom paths to ~/.bashrc
export USE_CCACHE=1
export PATH=~/.bin:~/.pushbullet:$PATH
