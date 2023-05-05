#!/usr/bin/env python3


import os
import re
import subprocess
import pandas as pd
import socket
import nmap
import json

def arp_scan():
    arp_result = subprocess.check_output("sudo arp-scan -l", shell=True).decode('utf-8')
    lines = arp_result.split("\n")[2:-4]
    devices = []
    for line in lines:
        columns = line.split("\t")
        ip_address = columns[0].strip()
        mac_address = columns[1].strip()
        device_name = columns[2].strip()
        devices.append((ip_address, mac_address, device_name))
    return devices

def nmap_scan(devices):
    nm = nmap.PortScanner()
    for device in devices:
        try:
            nm.scan(hosts=device[0], arguments='-sn')
            host_name = nm[device[0]].hostnames()[0]['name']
        except Exception as e:
            host_name = 'Unknown'
        yield device[0], device[1], device[2], host_name

def save_trusted_devices_to_file(devices_df):
    devices_df.to_json("trusted_devices.json", orient='records')

def main():
    devices = arp_scan()
    network_devices = list(nmap_scan(devices))
    df = pd.DataFrame(network_devices, columns=['IP Address', 'MAC Address', 'Device Name', 'Host Name'])

    # Save the dataframe to an Excel file
    df.to_excel("network_devices.xlsx", index=False)
    print("The network devices information has been saved to 'network_devices.xlsx'")

    # Save trusted devices to a local JSON file
    save_trusted_devices_to_file(df)

    return df

if __name__ == "__main__":
    main()
