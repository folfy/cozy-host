#! /usr/bin/env bash

# inherit traps in subfunctions
set -E

main() {
	if [[ $1 == userconf ]]; then
		# helper to run configuration steps as desired user
		xfce_conf
		dotfiles
		exit
	elif [[ -n $1 ]]; then
		local user="$1"
	fi
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
	grubconf
	grubtheme
	userconf "$user"

	read -t 10 -n 1 -p "Finished setup, rebooting in 10s - Press any key to continue..."
	reboot
}

getuser() {
	if [[ -n $user ]]; then
		echo "$user"
	elif [[ $EUID -ne 0 ]]; then
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

modconf() {
	# set option if file if not existing yet, otherwise modify line
	file="$1"
	option="$2"
	value="$3"

	if grep -q "^$option" "$file"; then
		sed -i "s/^$option.*/$option=$value/" "$file"
	else
		echo "$option=$value" >> "$file"
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
	if [ -b /dev/cdrom ]; then
		eject /dev/cdrom
	elif [ -b /dev/sr0 ]; then
		eject /dev/sr0
	elif [ -b /dev/dvd ]; then
		eject /dev/dvd
	else
		read -p "Cannot eject DVD, please remove disk manually, and press enter to continue..."
	fi
}

setup() {
	local user="$1"

	# Swap optimization
	modconf "/etc/sysctl.conf" "vm.swappiness" 20
	# modconf "/etc/sysctl.conf" "vm.vfs_cache_pressure" 50
	modconf "/etc/sysctl.conf" "zswap.enabled" 1
	modconf "/etc/sysctl.conf" "zswap.max_pool_percent" 25

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
	addpkg expect           # Expect tcl scripting language
	addpkg curl             # Fetch text from URL easily
	addpkg stow             # Symlink tool (used for dotfiles)
	addpkg tig              # ncurses-based terminal git-frontend
	# addpkg git-crypt        # encrypted file storage in git
	addpkg tree             # simple tool to show directory-structure as tree
	addpkg ripgrep          # fast grep alternative
	addpkg fzf              # fuzzy find tool
	addpkg ruby             # used for tmuxinator
	addpkg fonts-hack-ttf   # nice font (e.g. for vim)
	# addpkg fonts-powerline  # fonts pached for powerline

	# themes
	apt-add-repository -y ppa:numix/ppa
	addpkg numix-gtk-theme
	addpkg numix-icon-theme-circle

	# veracrypt
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
	apt autoremove -y
}

grubconf() {
	# make os selectable before reboot via "grub-reboot <os-num>"
	# modconf "/etc/default/grub" "GRUB_DEFAULT" "saved"

	# always show grub, even if only one os was found
	# modconf "/etc/default/grub" "GRUB_TIMEOUT_STYLE" menu
	# modconf "/etc/default/grub" "GRUB_TIMEOUT" 3

	# patch recordfail timeout from 30s to 3s
	# workaround for bug on systems with LVM to always trigger this
	# http://bugs.launchpad.net/ubuntu/+source/grub2/+bug/1815002
	modconf "/etc/default/grub" "GRUB_RECORDFAIL_TIMEOUT" 3

	sudo update-grub
	# grub-set-default 0
}

grubtheme() {
	if ! [ -d grub2-themes ]; then
		git clone --depth 1 https://github.com/vinceliuice/grub2-themes
	fi
	cd grub2-themes
	git pull
	sudo ./install.sh -b -v
	cd ..
}

xfce_conf(){
	xfconf-query -c xfwm4 -p /general/theme -nt string -s Numix
	xfconf-query -c xsettings -p /Net/ThemeName -nt string -s Numix
	xfconf-query -c xsettings -p /Gtk/MonospaceFontName -nt string -s "Hack 9"
	xfconf-query -c xfce4-power-manager -p /xfc4-power-manager/power-button-action -nt int -s 4

	if [ "$(vcheck)" -eq 0 ]; then
		xfconf-query -c xfce4-screensaver -p /saver/enabled -nt bool -s false
		xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/dpms-enabled -nt bool -s false
		xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/blank-on-ac -nt int -s 0
	fi
}

xfce_conf_work() {
	# disable automount
	xfconf-query -c thunar-volman -p /automount-drives/enabled -nt bool -s false
	xfconf-query -c thunar-volman -p /automount-media/enabled -nt bool -s false
	xfconf-query -c thunar-volman -p /autobrowse/enabled -nt bool -s false
}

setup_virt() {
	sudo apt-get install docker.io
	sudo apt-get install virt-manager
	sudo apt-get install ovmf #uefi support
	sudo usermod -a -G libvirt $user
	sudo usermod -a -G docker $user
}

enable_iommu() {
	modconf "/etc/default/grub" "RUB_CMDLINE_LINUX_DEFAULT" "quiet splash intel_iommu=on iommu=pt"
	modconf "/etc/default/grub" "RUB_CMDLINE_LINUX_DEFAULT" "quiet splash amd_iommu=on iommu=pt"
	update-grub
	# fetch groups:
	# for g in /sys/kernel/iommu_groups/*; do
	# 	echo "IOMMU Group ${g##*/}:"
	# 	for d in $g/devices/*; do
	# 		echo -e "\t$(lspci -nns ${d##*/})"
	# 	done;
	# done;
}

userconf() {
	echo "initializing dotfiles..."
	su $1 -c "'$0' userconf"
}

dotfiles() {
	echo "dotfiles for $USER"
	cd "$(dirname "$0")"
	git submodule update --init
	cd dotfiles
	git checkout master
	echo "Linking dotfiles"
	./link.sh
	echo "Running post-config script"
	./postconfig.sh
}

errorhandler() {
	echo "Error on line $1 - Command failed: '$2'"
	read -p "Press enter to continue..."
}

# capture last command for errorhandler
trap 'last_command=$BASH_COMMAND' DEBUG
trap 'errorhandler "$LINENO" "$last_command"' ERR


main "$@"
