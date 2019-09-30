#! /usr/bin/env bash

# TODO:
# load dotfiles

main() {
	if [[ $EUID -ne 0 ]]; then
		sudo "$0" "$@"
		exit
	fi

	local virt="$(vcheck)"
	local user="$(getuser)"

	echo "Running setup on $(vtype "$virt") host '$HOSTNAME' for user '$user'"
	read -p "Press enter to continue..."

	if [ "$virt" -eq 0 ]; then
		vsetup
	fi

	setup "$user"
	# load dotfiles

	read -t 10 -n 1 -p "Finished setup, rebooting in 10s - Press any key to abort..."
	reboot
}

getuser() {
	if [[ $EUID -ne 0 ]]; then
		echo "$USER"
	elif [[ -n $SUDO_USER ]]; then
		echo "$SUDO_USER"
	elif [[ -n $LOGNAME ]]; then
		echo "$LOGNAME"
	else
		echo "Failed to get username!"
		return 1
	fi
}

vcheck() {
	# check if inside VM (setup virtualbox)
	grep -q "^flags.*\ hypervisor" /proc/cpuinfo
	echo $?
}

vtype() {
	if [ "$1" -eq 0 ]; then
		echo -n "virtual"
	elif [ "$1" -eq 1 ]; then
		echo -n "physical"
	else
		echo "ERROR: Unknown return code \"$1\" from vcheck"
	fi
}

vsetup() {
	vboxadd="/media/*/VBOXADDITIONS_*/autorun.sh"
	vboxadd2="/media/*/VBox_GAs_*/autorun.sh"

	while ! [ -f $vboxadd ] && ! [ -f $vboxadd2 ]; do
		echo "Could not find vbox additions DVD under path '$vboxadd' or '$vboxadd2'!"
		read -p "Press enter to retry..."
	done
	
	if ! [ -f $vboxadd ]; then
		vboxadd="$vboxadd2"
	fi

	# build essentials for rebuilding the kernel (required)
	sudo apt install -y build-essential gcc make perl dkms

	eval $vboxadd
	eject /dev/dvd
}

setup() {
	local user="$1"

	# Swap optimization
	#TODO: Set option via grep&sed&echo, avoid double entries (dedicated function)
	# grep -q '^option' file && sed -i 's/^option.*/option=value/' file || echo 'option=value' >> file
	echo "vm.swappiness=10
vm.vfs_cache_pressure=50
zswap.enabled=1" >> /etc/sysctl.conf

	# Update system
	apt -y update
	apt -y upgrade
	apt -y full-upgrade

	# Init package list
	pkgs=""
	addpkg(){ pkgs+=" $@";}
	
	# dependencies
	addpkg default-jre      # java

	# wireshark
	# for unattended setup:
	DEBIAN_FRONTEND=noninteractive apt-get -y install wireshark
	echo "wireshark-common wireshark-common/install-setuid boolean true" | debconf-set-selections
	DEBIAN_FRONTEND=noninteractive dpkg-reconfigure wireshark-common
	# regular setup: apt install wireshark
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
	addpkg ripgrep          # fast grep alternative
	addpkg fzf              # fuzzy find tool
	addpkg ruby             # used for tmuxinator
	addpkg fonts-hack-ttf   # nice font (e.g. for vim)

	# themes
	apt-add-repository -y ppa:numix/ppa
	addpkg numix-gtk-theme
	addpkg numix-icon-theme-circle
	
	# veracrypt
	#not yet supporting ubuntu 19.10
	#apt-add-repository -y ppa:unit193/encryption
	#addpkg veracrypt

	# update new repositories first
	apt update
	apt install -y $pkgs

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
