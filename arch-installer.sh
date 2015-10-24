#!/usr/bin/bash

#
# Define settings
#
HOSTNAME="sample-host"
ROOT_PASSWORD="password"

STORAGE=/dev/sda
BOOT_SIZE=512MB
SWAP_SIZE=4GB
ROOT_SIZE=10GB

# for ansible
INSTALL_PACKAGE=(base intel-ucode grub)
EXTRA_INSTALL_PACKAGE=()

# Network
NETWORK_INTERFACE=eth0
NETWORK_CONFIG=$(cat<< EOF
Description='A basic static ethernet connection'
Interface=$NETWORK_INTERFACE
Connection=ethernet
IP=static
Address='192.168.1.100/24'
Gateway='192.168.1.1'
#Router=('192.168.0.0/24 via 192.168.1.2')
DNS='192.168.1.1'
#DNS=('8.8.8.8', '4.4.4.4')
EOF
)

KEYMAP=jp106
LOCALE_CONF=ja_JP.UTF-8
LOCALE_GEN=$(cat <<- EOF
	en_US.UTF-8 UTF-8
	ja_JP.UTF-8 UTF-8
	EOF
)

#
# Define functions
#
function intro() {
	echo "***********************************"
	echo "****** Hello, Arch Installer ******"
	echo "***********************************"
	echo "* Install Arch Linux"
	echo "* With:    BIOS/MBR/GRUB"
	echo "* Dev:     $STORAGE"
}

function make_partition() {
	echo "****** Make partition ******"
	fdisk $STORAGE <<- EOF
		n
		p
		
		
		+$BOOT_SIZE
		n
		p
		
		
		+$SWAP_SIZE
		n
		p
		
		
		+$ROOT_SIZE
		n
		p
		
		
		a
		1
		t
		2
		82
		w
		EOF
}

function format_disk() {
	echo "****** Format disk ******"
	yes | mkfs.ext4 ${STORAGE}1
	yes | mkfs.ext4 ${STORAGE}3
	yes | mkfs.ext4 ${STORAGE}4
	mkswap ${STORAGE}2
	swapon ${STORAGE}2
}

function mount_disk() {
	echo "****** mount disk ******"
	mount ${STORAGE}3 /mnt
    mkdir /mnt/boot
    mkdir /mnt/home
    mount ${STORAGE}1 /mnt/boot
    mount ${STORAGE}4 /mnt/home
}

function install_packages() {
	echo "****** Install packages ******"
	echo "* Update mirrorlist with Japan mirror"
	grep --no-group-separator -A 1 Japan < /etc/pacman.d/mirrorlist > ./tmp_mirrorlist
	cat /etc/pacman.d/mirrorlist >> ./tmp_mirrorlist
	cp ./tmp_mirrorlist /etc/pacman.d/mirrorlist
	rm ./tmp_mirrorlist
	echo "* Update time"
	sntp -b ntp.nict.jp
	hwclock -w --utc
	echo "* Update keys"
	rm -rf /etc/pacman.d/gnupg/*
	pacman-key --init
	pacman-key --populate archlinux
	echo "* Install packages"
	pacstrap /mnt ${INSTALL_PACKAGE[@]} ${EXTRA_INSTALL_PACKAGE[@]} 
}

function create_configs() {
	echo "****** Create configs ******"
	echo "* Keymap"
	echo "KEYMAP=$KEYMAP" > /mnt/etc/vconsole.conf
	echo "* Ethernet"
	echo "$NETWORK_CONFIG" > /mnt/etc/netctl/$NETWORK_INTERFACE
	echo "* fstab"
	genfstab -U -p /mnt > /mnt/etc/fstab
	echo "* Ethernet"
	echo "$NETWORK_CONFIG" > /mnt/etc/netctl/$NETWORK_INTERFACE
	echo "* HostName"
	echo "$HOSTNAME" > /mnt/etc/hostname
	echo "* Locale"
	echo "LANG=$LOCALE_CONF" > /mnt/etc/locale.conf
	echo "$LOCALE_GEN" > /mnt/etc/locale.gen
	echo "* sshd for logging with password as root"
	sed -i -e "/#PermitRootLogin/i PermitRootLogin yes" /mnt/etc/ssh/sshd_config
}

function install_under_chroot() {
	CHROOT=/mnt
	echo "****** Install under chroot ******"
	echo "* Enable eth0"
	arch-chroot $CHROOT netctl enable eth0
	echo "* Enable sshd"
	arch-chroot $CHROOT systemctl enable sshd.service
	echo "* Generate locale"
	arch-chroot $CHROOT locale-gen
	echo "* Set time zone"
	arch-chroot $CHROOT ln -s /usr/share/zoneinfo/Asia/Tokyo /etc/localtime
	echo "* Install grub"
	arch-chroot $CHROOT grub-install --recheck $STORAGE
	arch-chroot $CHROOT grub-mkconfig -o /boot/grub/grub.cfg
	echo "* Set password"
	arch-chroot $CHROOT passwd root <<- EOF
		$ROOT_PASSWORD
		$ROOT_PASSWORD
		EOF
}

#
# Install
#

intro
make_partition
format_disk
mount_disk
install_packages
create_configs
install_under_chroot

