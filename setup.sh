#! /usr/bin/env bash

# TODO:

main() {
	if [[ $EUID == 0 ]] || [[ $1 == sudo ]]; then
		hook
	else
		sudo "$0" sudo "$@"
	fi
}

hook() {
	local virt=$(vcheck)	
	echo "Running setup on $(vtype $virt) host '$HOST' for user '$USER'"
	read -p "Press enter to continue..."

	if $virt; then
		vsetup
	fi
	setup "$USER"
	
	read -t 10 -n 1 -p "Finished setup, rebooting in 10s - Press any key to abort..."
}

vcheck() {
	# check if inside VM (setup virtualbox)
	grep -q "^flags.*\ hypervisor" /proc/cpuinfo
	echo $?
}

vtype() {
	if $1; then
		echo -n "physical"
	else
		echo -n "virtual"
	fi
}

vsetup() {
	vboxadd="/media/*/VBOXADDITIONS_*/autorun.sh
	
	while ! [ -f $vboxadd ]; do
		echo "Could not find vbox additions DVD under path '$vboxadd'!"
		prompt -p "Press enter to retry..."
	done
	
	eval $vboxadd
	eject /dev/dvd
	
}

setup() {
	local user="$1"

	# Swap optimization
	echo "vm.swappiness=10
vm.vfs_cache_pressure=50
zswap.enabled=1" >> /etc/sysctl.conf

	# Update system
	apt update
	apt upgrade
	apt full-upgrade
	
	# Init package list
	pkgs=""
	addpkg() {pkgs+=" $@"}

	# wireshark
	# for unattended setup:
	DEBIAN_FRONTEND=noninteractive apt-get -y install wireshark
	# apt install wireshark
	usermod -a -G wireshark "$user"

	# multimedia
	snap install spotify
	
	# tools
	addpkg tmux
	addpkg vim-gtk3
	
	# system
	addpkg gparted          # Main partition tool
	addpkg partitionmanager # KDE Partition Manager (supports LVM)

	# remote access
	addpkg openssh-server   # ssh-server

	# utils
	addpkg htop             # Better process manager
	addpkg curl             # Fetch text from URL easily
	addpkg stow             # Symlink tool (used for dotfiles)
	addpkg tig              # ncurses-based terminal git-frontend
	addpkg tree             # simple tool to show directory-structure as tree
	addpkg ruby             # used for tmuxinator
	addpkg fonts-hack-ttf   # nice font (e.g. for vim)
	
	# themes
	apt-add-repository -y ppa:numix/ppa
	addpkg numix-gtk-theme
	addpkg numix-icon-theme-circle

	apt install $pkgs

	# disable ssh-server (not configured yet)
	systemctl stop ssh
	systemctl disable ssh

	# tmuxinator requires ruby
	gem install tmuxinator
	
	# Cleanup
	apt clean
	apt autoremove
}

main "$@"
