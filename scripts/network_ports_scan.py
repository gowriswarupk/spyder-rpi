#!/usr/bin/env python3

import nmap
import pandas as pd
import json
from network_device_scan import main as scan_network

def port_scan(device_ip):
    nm = nmap.PortScanner()
    nm.scan(hosts=device_ip, arguments='-p-')
    open_ports = [int(port) for port, info in nm[device_ip]['tcp'].items() if info['state'] == 'open']
    return open_ports

def scan_ports_for_devices(devices_df):
    port_scan_results = []

    for index, device in devices_df.iterrows():
        device_ip = device['IP Address']
        device_name = device['Device Name']
        host_name = device['Host Name']
        mac_address = device['MAC Address']

        open_ports = port_scan(device_ip)
        port_scan_results.append({
            'Device Name': device_name,
            'Host Name': host_name,
            'IP Address': device_ip,
            'MAC Address': mac_address,
            'Open Ports': open_ports
        })

    return port_scan_results

def save_port_scan_results_to_file(results_df):
    results_df.to_json("port_scan_results.json", orient='records')

def main():
    devices_df = scan_network()
    port_scan_results = scan_ports_for_devices(devices_df)

    results_df = pd.DataFrame(port_scan_results)
    results_df.to_excel("port_scan_results.xlsx", index=False)
    print("The port scan results have been saved to 'port_scan_results.xlsx'")

    save_port_scan_results_to_file(results_df)

if __name__ == "__main__":
    main()
