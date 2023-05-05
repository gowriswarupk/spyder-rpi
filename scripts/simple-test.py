#!/usr/bin/env python3


import os
import socket
import struct

# Get the IP address of the network interface that the Raspberry Pi is connected to
def get_ip_address(ifname):
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    return socket.inet_ntoa(fcntl.ioctl(s.fileno(), 0x8915, struct.pack('256s', bytes(ifname[:15], 'utf-8')))[20:24])

# Determine the name of the network interface that the Raspberry Pi is connected to
def get_interface_name():
    with open('/proc/net/route') as f:
        for line in f:
            fields = line.strip().split()
            if fields[1] != '00000000' or not int(fields[3], 16) & 2:
                continue
            return fields[0]

# Get the IP address of the network interface that the Raspberry Pi is connected to
interface_name = get_interface_name()
ip_address = get_ip_address(interface_name)

# Run an Nmap scan on the network
os.system(f"nmap -sP {ip_address}/24")

# Open the file containing the scan results
with open("/proc/net/arp", "r") as f:
    # Skip the first line (header)
    f.readline()
    # Print each line of the file
    for line in f:
        # Split the line into columns
        cols = line.split()
        # Print the device name, IP address, and MAC address in separate columns
        print(cols[0], cols[1], cols[3], sep="\t")

# Print success message
print("Script executed from mobile")

