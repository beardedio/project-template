#!/bin/bash
set -euo pipefail

# Colorize me baby
green() { printf '\e[1;32m%b\e[0m\n' "$@"; }
yellow() { printf '\e[1;33m%b\e[0m\n' "$@"; }
red() { printf '\e[1;31m%b\e[0m\n' "$@"; }

# ref: https://askubuntu.com/a/30157/8698
if ! [ "$(id -u)" = 0 ]; then
   red "The script need to be run as root." >&2
   exit 1
fi

if [ "$SUDO_USER" ]; then
    real_user=$SUDO_USER
else
    real_user=$(whoami)
fi


# Check if prerequisites are installed
green "Checking for prerequisites"

if [[ $(command -v brew) == "" ]]; then
    red "Hombrew is required to run this script, please install."
    yellow "To install go to https://brew.sh/"
    exit 1
else
    green "Homebrew Found!"
    green "Updating Homebrew..."
    sudo -u "$real_user" brew update
fi

if [[ $(command -v jq) == "" ]]; then
    red "jq is required to run this script, please install."
    yellow "To install run 'brew install jq'"
    exit 1
fi

if [[ $(command -v sponge) == "" ]]; then
    red "sponge is required to run this script, please install."
    yellow "To install run 'brew install moreutils'"
    exit 1
fi

if [[ $(command -v docker) == "" ]]; then
    red "Docker for Mac is required to run this script, please install."
    yellow "To install go to https://docs.docker.com/docker-for-mac/install/"
    exit 1
fi



# Add new loopback address
green "Adding loopback address"
sudo ifconfig lo0 alias 10.254.254.1/32


# Setup new loopback address at reboot
if [ -f /Library/LaunchDaemons/local.dnsloopback.plist ] ; then
    sudo rm /Library/LaunchDaemons/local.dnsloopback.plist
fi
sudo defaults write /Library/LaunchDaemons/local.dnsloopback.plist Label dnsloopback
sudo defaults write /Library/LaunchDaemons/local.dnsloopback.plist ProgramArguments -array /sbin/ifconfig lo0 alias 10.254.254.1/32
sudo defaults write /Library/LaunchDaemons/local.dnsloopback.plist RunAtLoad -bool true
sudo plutil -convert xml1 /Library/LaunchDaemons/local.dnsloopback.plist


# Install and configure dnsmasq for local domain
green "Checking for dnsmasq"
if [[ $(sudo -u "$real_user" brew ls --versions dnsmasq) == "" ]]; then
    sudo -u "$real_user" brew install dnsmasq
fi

# Copy over the default dnsmasq config file
if [ ! -f /usr/local/etc/dnsmasq.conf ]; then
    sudo cp /usr/local/opt/dnsmasq/dnsmasq.conf.example /usr/local/etc/dnsmasq.conf
fi

# Configure dnsmasq to respond to the test TLD
green "Configuring .test TLD"
if grep -q 'address=/test/10.254.254.1' "/usr/local/etc/dnsmasq.conf"; then
    green "Test domain is already configured, skipping..."
else
    sudo echo 'address=/test/10.254.254.1' | sudo tee -a /usr/local/etc/dnsmasq.conf > /dev/null
fi
sudo brew services restart dnsmasq


# Point local dns to dnsmasq
green "Configuring MacOS to resolve .test TLD via dnsmasq"
sudo mkdir -p /etc/resolver
if [ -f /etc/resolver/test ]; then
    sudo rm /etc/resolver/test
fi
echo 'nameserver 10.254.254.1' | sudo tee /etc/resolver/test > /dev/null


# Point “Docker for Mac" to local dns
green "Point Docker at dnsmasq to resolve domains from inside docker containers"
jq '. + {"dns":["10.254.254.1"]}' ~/.docker/daemon.json | sponge ~/.docker/daemon.json


green "Setup is complete!"
yellow '##########################################################################'
yellow "# For these changes to take effect, you MUST restart the docker service! #"
yellow "# You can do this from the menu bar 'Docker > Restart'                   #"
yellow '##########################################################################'