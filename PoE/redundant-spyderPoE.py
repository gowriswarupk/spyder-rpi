#!/usr/bin/env python3
import os
import subprocess
import time

def find_open_networks():
    available_networks = subprocess.check_output("nmcli device wifi list", shell=True).decode()
    lines = available_networks.split("\n")[1:]
    open_networks = []

    for line in lines:
        if " -- " not in line:
            continue
        parts = line.strip().split()
        ssid = parts[-1]
        security = parts[-4]

        if security.lower() == "--":
            open_networks.append(ssid)

    return open_networks

def connect_to_open_network(network_name):
    print(f"Found and connecting to open network: {network_name}")
    os.system(f"nmcli device wifi connect '{network_name}'")
    
def run_nmap_device_scan(network_name):
    scan_result = subprocess.check_output(f"nmap -sn 192.168.0.0/24", shell=True).decode()
    devices = []
    lines = scan_result.split("\n")
    
    for i in range(0, len(lines), 3):
        if lines[i].startswith("Nmap scan report for"):
            host = lines[i].split()[-1]
            mac = lines[i+2].split()[-2]
            devices.append((host, mac))

    with open(f"{network_name}_device_scan.txt", "w") as f:
        for host, mac in devices:
            f.write(f"{host} {mac}\n")
            print(f"Device: {host}, MAC: {mac}")

def run_open_port_scan(network_name):
    scan_result = subprocess.check_output("nmap -p- --open 192.168.0.0/24", shell=True).decode()
    with open(f"{network_name}_open_port_scan.txt", "w") as f:
        f.write(scan_result)
        print(scan_result)

def run_tshark(network_name, duration):
    pcap_file = f"{network_name}_capture.pcap"
    os.system(f"tshark -i wlan0 -a duration:{duration} -w {pcap_file}")
    os.system(f"tshark -r {pcap_file} -q -z conv,tcp > {network_name}_report.txt")
    with open(f"{network_name}_report.txt", "r") as f:
        print(f.read())

def main():
    open_networks = find_open_networks()

    if not open_networks:
        print("No open network found.")
        return

    for network_name in open_networks:
        connect_to_open_network(network_name)
        run_nmap_device_scan(network_name)
        run_open_port_scan(network_name)
        run_tshark(network_name, 30)
        print("Disconnecting from", network_name)
        os.system("nmcli device disconnect wlan0")

if __name__ == "__main__":
    main()

