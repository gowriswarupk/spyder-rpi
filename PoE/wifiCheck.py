#!/usr/bin/env python3

import wifi

# Scan for nearby access points
access_points = wifi.Cell.all('wlan0')

# Print information about each access point
for ap in access_points:
    print(f"SSID: {ap.ssid}")
    print(f"\tChannel: {ap.channel}")
    print(f"\tSignal: {ap.signal}")
    
    if ap.encrypted == False:
        print("\tOpen network detected!")
    else:
        print(f"\tNetwork is secured with {ap.encryption_type} encryption.")

