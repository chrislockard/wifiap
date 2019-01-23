# wifiap
Automate the standup of a wifi access point in Kali Linux to monitor WiFi traffic 

# Prerequisites
WiFi Adapter with good driver support, ability to utilize all WiFi modes, and preferably packet injection. I use the Alfa AWUS051NH, but if I had to buy a new one today, it would be the Alfa AWUS036NHA 

## dnsmasq and hostapd
`apt-get install -y dnsmasq hostapd`

## Edit dnsmasq.conf
Prevent dns on the loopback interface by commenting out line 115 (or nearby) containing:
```
no-dhcp-interface=lo
```

Enable the integrated DHCP server and provide IP address range and lease time (around line 157):
```
dhcp-range=10.0.0.2,10.0.0.20,12h
```
*note:* increase 20 as needed to allow more devices on the subnet and the dhcp lease as desired

## Create hostapd.conf
This is the file hostapd will use for configuration. Specify the interface, driver (nl80211 is the one I’ve had most success with), SSID, hardware mode, channel, and security parameters:

```
interface=wlan0
driver=nl80211
ssid=<ssid can contain spaces>
hw_mode=g
channel=11
wpa=2
wpa_passphrase=<password>
```

## VM Network Configuration
Ensure the VM is set to *Bridged* networking on the interface that will be providing Internet access to the VM

# Usage
Ensure the kernel picked up your wifi adapter:
```
ifconfig -a
```

Run `./wifiap.sh` . It will prompt you for three things:
1. Monitor interface (this will likely be wlan0 or wlan1 in Kali)
2. Path to hostapd.conf (This will be your custom location. I keep mine in /root/hostapd.conf)
3. Path to dnsmasq.conf (This will be /etc/dnsmasq.conf or your custom location)

Wait for the script to provide the SSID in green text (pulled from your hostapd.conf). This AP should now be selectable from your devices. Connect all devices you wish to monitor traffic for to this AP.

Start Wireshark and capture on the Monitor interface you specified when you ran the script.

# Troubleshooting
This script was developed and tested on Kali 2018.1 in a Parallels 13 VM. It has been tested in a Kali 2018.3 Parallels 14 VM. If you run into any issues, please report them.
