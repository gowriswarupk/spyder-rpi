#!/usr/bin/env python3

from scapy.all import ARP, Ether, srp
import socket


def get_device_name(ip):
    try:
        return socket.gethostbyaddr(ip)[0]
    except socket.herror:
        return 'Unknown'


def get_connected_devices(ip_range):
    arp = ARP(pdst=ip_range)
    ether = Ether(dst="ff:ff:ff:ff:ff:ff")
    packet = ether / arp

    result = srp(packet, timeout=3, verbose=0)[0]

    devices = []
    for sent, received in result:
        device = {
            'ip': received.psrc,
            'mac': received.hwsrc,
            'name': get_device_name(received.psrc)
        }
        devices.append(device)

    return devices


def main():
    ip_range = "192.168.1.0/24"  # Replace with your network range

    connected_devices = get_connected_devices(ip_range)

    for device in connected_devices:
        print(f"{device['name']} ({device['ip']}) - MAC: {device['mac']}")


if __name__ == "__main__":
    main()


