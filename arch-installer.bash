#!/usr/bin/bash

#
# Define settings
#
HOSTNAME="sample-host"
ROOT_PASSWORD="password"

STORAGE=/dev/sda
BOOT_SIZE=512MB
ROOT_SIZE=10GB

INSTALL_PACKAGE=(base linux linux-firmware intel-ucode openssh netctl)
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
LOCALE_CONF=en_US.UTF-8
LOCALE_GEN=$(cat <<- EOF
	en_US.UTF-8 UTF-8
	EOF
)
# ja_JP.UTF-8 UTF-8

#
# Define functions
#
function intro() {
	echo "***********************************"
	echo "****** Hello, Arch Installer ******"
	echo "***********************************"
	echo "* Install Arch Linux"
	echo "* With:    BIOS/UEFI/GRUB"
	echo "* Dev:     $STORAGE"
}

function make_partition() {
	echo "****** Make partition ******"
	gdisk <<- EOF
$STORAGE
n


+$BOOT_SIZE
EF00
n


+$ROOT_SIZE
8300
n



8300
w
y
EOF
}

function format_disk() {
	echo "****** Format disk ******"
	yes | mkfs.fat -F32 ${STORAGE}1
	yes | mkfs.ext4 ${STORAGE}2
	yes | mkfs.ext4 ${STORAGE}3
}

function mount_disk() {
	echo "****** mount disk ******"
	mount ${STORAGE}2 /mnt
	mkdir /mnt/boot
	mkdir /mnt/home
	mount ${STORAGE}1 /mnt/boot
	mount ${STORAGE}3 /mnt/home
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
	#rm -rf /etc/pacman.d/gnupg/*
	#pacman-key --init
	#pacman-key --populate archlinux
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
	echo "* Enable $NETWORK_INTERFACE"
	arch-chroot $CHROOT netctl enable $NETWORK_INTERFACE
	echo "* Enable sshd"
	arch-chroot $CHROOT systemctl enable sshd.service
	echo "* Generate locale"
	arch-chroot $CHROOT locale-gen
	echo "* Set time zone"
	arch-chroot $CHROOT ln -s /usr/share/zoneinfo/Asia/Tokyo /etc/localtime
	echo "* Set systemd-boot"
	arch-chroot $CHROOT bootctl --path=/boot install
	echo "title   Arch Linux" > $CHROOT/boot/loader/entries/arch.conf
	echo "linux   /vmlinuz-linux" >> $CHROOT/boot/loader/entries/arch.conf
	echo "initrd  /initramfs-linux.img" >> $CHROOT/boot/loader/entries/arch.conf
	echo "options root=PARTUUID=$(blkid -s PARTUUID -o value /dev/sda2) rw" >> $CHROOT/boot/loader/entries/arch.conf
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

