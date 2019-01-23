#!/bin/bash

echo "This script will set up a WiFi AP using dnsmasq and hostapd. The 
configurations for these are pulled from /etc/dnsmasq.conf and 
/root/hostapd.conf, respectively.

If you do not have these packages installed already, install them with:
$ apt-get install dnsmasq hostapd
"

read -p "Enter Monitor Interface (likely wlan0 or wlan1): " monint
read -p "Enter path to hostapd configuration: " hostconf
read -p "Enter path to dnsmasq configuration: " dnsconf

# Catch Ctrl-C and exit cleanly
function ctrl_c() {
	echo $'\n\nCleaning up'
	echo $'\nKilling processes...'
	echo $'===================='
	killall -v dnsmasq
	killall -v hostapd
	echo $'..done!\n' 
	echo $'\nFlushing iptables rules:'
	echo $'========================'
	iptables -v -F
	iptables -v -F -t nat
	echo $'..done!\n'
	echo $'\nRestoring old iptables rules:'
	echo $'============================='
	iptables-restore < /tmp/iptablesrules.fw
	echo $'..done!\n'
	echo $'Disabling IP Forwarding:'
	echo $'========================'
	sysctl net.ipv4.ip_forward=0
	echo $'..done!\n'
	echo $'Restarting network manager:'
	echo $'========================='
	service network-manager restart
	echo $'..done!\n'
}
trap ctrl_c INT

echo $'\nStopping and disabling any existing services:'
echo $'==============================================='
service hostapd stop
service dnsmasq stop
pkill -9 dnsmasq
pkill -9 hostapd

echo $'\nFlushing any existing firewall rules:'
echo $'====================================='
iptables -F
iptables -F -t nat

#echo $'\nAdding wireless adapter to NetworkManager exclusion list:'
#echo $'========================================================='
#echo "unmanaged-devices=mac:$(iw dev | grep addr | tr -d '\t' | cut -d ' ' -f 2)" >> /etc/NetworkManager/NetworkManager.conf

echo "
Bringing up $monint interface:"
echo $'============================'
nmcli radio wifi off
rfkill unblock wlan
iwconfig $monint mode monitor
ifconfig $monint 10.0.0.1/24 up

echo $'\nEnabling IP forwarding:'
echo $'======================='
sysctl net.ipv4.ip_forward=1

echo $'\nSaving existing up iptables rules:'
echo $'=================================='
iptables-save > /tmp/iptablesrules.fw

echo $'\nSetting up iptables rules:'
echo $'============================'		
iptables --delete-chain
iptables --table nat --delete-chain
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE #iptables --table nat --append POSTROUTING --out-interface eth0 -j  MASQUERADE
iptables --append FORWARD --in-interface $monint -j ACCEPT

echo $'\nStarting hostapd service:'
echo $'========================='
hostapd -B $hostconf


echo $'\n=========================================================================='
echo $'Done! You should be able to select the wifi SSID outlined in hostapd.conf:'
tput setaf 2; grep ssid $hostconf | cut -d '=' -f 2
tput sgr0
echo "To quit and clean up, press $(tput setaf 1)Ctrl-C$(tput sgr0)"
echo $'=========================================================================='

echo $'\nBringing up dnsmasq service:'
echo $'============================='
dnsmasq -C $dnsconf	-d