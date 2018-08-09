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
	
	# tools
	addpkg tmux
	addpkg vim-gtk3
	
	# system
	addpkg gparted          # Main partition tool
	addpkg partitionmanager # KDE Partition Manager (supports LVM)

	# utils
	addpkg htop             # Better process manager
	addpkg curl             # Fetch text from URL easily
	addpkg stow             # Symlink tool (used for dotfiles)
	addpkg tig              # ncurses-based terminal git-frontend
	addpkg tree             # simple tool to show directory-structure as tree
	addpkg openssh-server   # ssh-server
	addpkg ruby             # used for tmuxinator
	addpkg fonts-hack-ttf   # nice font (e.g. for vim)
	apg-get install $pkgs

	# disable ssh-server (not configured yet)
	systemctl stop ssh
	systemctl disable ssh

	# tmuxinator requires ruby
	gem install tmuxinator
EOF
