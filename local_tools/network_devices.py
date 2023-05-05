#!/usr/bin/env python3

import os
import time
from scapy.all import ARP, Ether, srp

def get_devices_on_network(interface, ip_range):
    arp = ARP(pdst=ip_range)
    ether = Ether(dst="ff:ff:ff:ff:ff:ff")
    packet = ether/arp
    result = srp(packet, timeout=3, iface=interface, inter=0.1, verbose=0)[0]

    devices = {}
    for sent, received in result:
        devices[received.psrc] = received.hwsrc
    return devices

def main():
    interface = "wlan0"
    ip_range = "192.168.1.0/24"

    known_devices = get_devices_on_network(interface, ip_range)

    while True:
        time.sleep(60)  # 1 minute loop
        devices = get_devices_on_network(interface, ip_range)

        for ip, mac in devices.items():
            if ip not in known_devices:
                known_devices[ip] = mac
                terminal_cmd = f'xfce4-terminal -T "New Device Alert" -x bash -c "echo \'New device on network:\nIP: {ip}\nMAC: {mac}\'; exec bash"'
                os.system(terminal_cmd)

if __name__ == "__main__":
    main()

