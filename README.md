Arch Installer
=====================

This project provides a bash script for installing Arch Linux (https://www.archlinux.org/) with GPT/UEFI/GRUB.

## Description

I wrote this script to install arch-linux on Hyper-V(Windows 10 pro).
I expected 2st generation of virtual machine, so I set up with GPT/UEFI/GRUB.
Perhaps, this completely works on other environment (e.g. physical machine or other virtual environment)

## Usage
First, boot arch linux instruction shell on your (virtual) machine. Next, run a script provided by this project.

### Interactive

    wget https://raw.githubusercontent.com/knaou/arch-installer/master/arch-installer.sh
    vim arch-installer.sh
    bash arch-installer.sh

### One-liner

I recommend to use curl and sed command.
 For example, when you want to build an environment with ansible,
 the follow a command prepares the minimal environment to work ansible remote command.(Ansible requires SSH and python2)

    curl https://raw.githubusercontent.com/knaou/arch-installer/master/arch-installer.sh | \
      sed -e "s/^HOSTNAME=.*$/HOSTNAME='localdev'/" | \
      sed -e "s/^ROOT_PASSWORD=.*$/ROOT_PASSWORD='hogehogepiyo'/" | \
      sed -e "s/^SWAP_SIZE=.*$/SWAP_SIZE=8GB/" | \
      sed -e "s/^EXTRA_INSTALL_PACKAGE=.*$/EXTRA_INSTALL_PACKAGE=(openssh python2)/" | \
      sed -e "s/^Address=.*$/Address='192.168.11.100/24'/" | \
      sed -e "s/^Gateway=.*$/Gateway='192.168.11.1'/" | \
      sed -e "s/^DNS=.*$/DNS='192.168.11.1'/" > install.sh

##  License
MIT License

## Link

* Author's blog: [http://naoblo.net/](http://naoblo.net/) (This blog was written by only Japanese.)
