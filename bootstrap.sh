#! /usr/bin/env bash

###
# bootstrap.sh
#
# Bootstrap script for single command execution of the cozy-host setup.
# Creates custom user with sudo-group, if not already logged in under preferred username.
#
# Runs temporary bootstrap-file under preferred or just created user:
#  - installs git
#  - shallow clone of repositroy
#  - runs the actual setup-script
###

fname="$(mktemp --tmpdir folfy_bootstrap.XXXX)"

cat >"$fname" <<"EOF"
#! /usr/bin/env bash

apt update && \
	apt install -y git

cd "$HOME" && \
	git clone --depth=5 https://github.com/folfy/cozy-host.git && \
	cd cozy-host && \
	./setup.sh || \
	echo "Clone/setup failed!"
EOF
chmod +x "$fname"

if [[ $USER != folfy ]] && [ $USER != ffritzer ]; then
	read -p "Enter name for personal superuser to be created (folfy/ffritzer): " username
	read -p "User '$username' will be created, press enter to continue..."
	
	sudo useradd $username
	sudo usermod -a -G sudo $username
	
	userflags="-i -u $username"
fi

sudo $userflags "$fname"

rm -f "$fname"
