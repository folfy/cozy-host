#! /usr/bin/env bash

###
# bootstrap.sh
#
# Bootstrap script for single command execution of the cozy-host setup.
# Creates custom user with sudo-group, if not already logged in under preferred username.
#
# Performed setup:
#  - install git
#  - shallow clone of repository
#  - run the actual setup-script
###

if [[ $USER != folfy ]] && [ $USER != ffritzer ]; then
	read -p "Enter name for personal superuser to be created (folfy/ffritzer): " username
	read -p "User '$username' will be created, press enter to continue..."
	
	sudo useradd $username
	sudo usermod -a -G sudo $username
	
	user=$username
else
	user=$USER
fi

sudo apt update &&
	sudo apt install -y git

sudo su $user <<"EOF"
	#ensure correct user is logged in, and no root environment is used for clone
	cd "$HOME" && \
		git clone --depth=5 https://github.com/folfy/cozy-host.git && \
		"$HOME/cozy-host/setup.sh" || \
		echo "Clone/setup failed!"
EOF
