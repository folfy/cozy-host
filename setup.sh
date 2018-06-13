#! /usr/bin/env bash

#
# Reminders:
#  xfce-terminal: colors, history, disable f10
#

sudo <<EOF
	# wireshark
	apt-get install wireshark
	usermod -a -G wireshark folfy

	# utils
	apt-get install curl stow tig ruby
	apt-get install openssh-server
	systemctl stop ssh
	systemctl disable ssh
	# tmuxinator requires ruby
	gem install tmuxinator
EOF
