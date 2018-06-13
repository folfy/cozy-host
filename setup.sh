#! /usr/bin/env bash

#
# Reminders:
#  xfce-terminal: colors, history, disable f10
#

sudo <<EOF
	# Init package list
	pkgs=""
	addpkg() {pkgs+=" $@"}

	# wireshark
	apt-get install wireshark
	usermod -a -G wireshark folfy

	# utils
	addpkg curl             # Fetch text from URL easily
	addpkg stow             # Symlink tool (used for dotfiles)
	addpkg tig              # ncurses-based terminal git-frontend
	addpkg tree             # simple tool to show directory-structure as tree
	addpkg openssh-server   # ssh-server
	addpkg ruby             # used for tmuxinator
	apg-get install $pkgs

	# disable ssh-server (not configured yet)
	systemctl stop ssh
	systemctl disable ssh

	# tmuxinator requires ruby
	gem install tmuxinator
EOF
