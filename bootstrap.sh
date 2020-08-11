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

errorhandler() {
	echo "Error on line $1 - Command failed: '$2'"
	exit 1
}

# capture last command for errorhandler
trap 'last_command=$BASH_COMMAND' DEBUG
trap 'errorhandler "$LINENO" "$last_command"' ERR

if [[ $USER != folfy ]] && [ $USER != ffritzer ]; then
	read -p "Enter name for personal superuser to be created (folfy/ffritzer): " username
	read -p "User '$username' will be created, press enter to continue..."

	sudo useradd $username
	sudo usermod -a -G sudo $username

	user=$username
else
	user=$USER
fi

if ! command -v git &> /dev/null; then
	echo "Installing git"
	sudo apt update
	sudo apt install -y git
fi

uhome="$(sudo su -c 'echo $HOME' $user)"
cd "$uhome"

echo "Running setup for user '$user'"
if ! [ -d "cozy-host" ]; then
	echo "Cloning repository"
	sudo su -c 'git clone --depth=5 https://github.com/folfy/cozy-host.git' $user
fi

echo "Updating repostory"
cd cozy-host
sudo su -c 'git pull' $user

echo "Starting setup script"
sudo ./setup.sh $user
# sudo su -c './setup.sh' $user
