#!/bin/bash

# Define the URL to display
url="https://tinyurl.com/2afh6f3v"

whiptail --title "Starting Install" --msgbox "Starting install now, if you wish to, click on the URL to open the original instruction page to understand the process.| Credits: Bob McKay | $url " 10 50

#chromium-browser "https://bobmckay.com/i-t-support-networking/hardware/create-a-security-honey-pot-with-opencanary-and-a-raspberry-pi-3-updated-2021/"

# Continue with the remaining script
echo "starting script..."

# Display message using whiptail
whiptail --title "OpenCanary Setup" --msgbox "This script will guide you through the process of setting up OpenCanary on your Raspberry Pi. Press OK to continue." 10 60

# SSH enabling
touch /boot/ssh.txt
whiptail --title "Enable SSH" --msgbox "SSH has been enabled. An empty file named ssh.txt has been created in the boot partition." 10 60

# Update the OS
whiptail --title "Updating OS" --msgbox "Starting full update of Raspbian. This may take a while." 10 60
sudo apt-get update && sudo apt-get upgrade -y

# Hide the Raspberry Pi
whiptail --title "Hide Raspberry Pi" --msgbox "Disguising the Raspberry Pi as a Synology NAS." 10 60
SYNOLOGY_MAC="00:11:32:B3:4D:F5"
echo "smsc95xx.macaddr=${SYNOLOGY_MAC}" | sudo tee -a /boot/cmdline.txt

# Update the hostname
SERVERNAME="FILESERVER"
sudo sed -i "s/raspberrypi/${SERVERNAME}/" /etc/hosts
echo "${SERVERNAME}" | sudo tee /etc/hostname

# Prompt the user to reboot or skip the reboot using whiptail
whiptail --title "Hostname Updated" --yesno "Hostname has been updated. Device should reboot the first time you run this script to install changes. If you are re-running this script, press no to skip this reboot. Do you want to reboot the system?" 10 60

if [ $? -eq 0 ]; then
    sudo reboot -n
else
    echo "Skipping reboot."
fi

# OpenCanary Installation
whiptail --title "OpenCanary Installation" --msgbox "Beginning OpenCanary installation." 10 60

# Install git
sudo apt install git -y

# Install cryptography prerequisites
sudo apt-get install build-essential libssl-dev libffi-dev python-dev -y

# Install pip for Python 3
sudo apt-get install python3-pip -y

# Upgrade python setuptools using pip
sudo pip3 install --upgrade setuptools

# Clone and setup OpenCanary
git clone https://github.com/thinkst/opencanary
cd opencanary
sudo python3 setup.py install

# Install network add-ons
sudo pip3 install scapy pcapy

# Fix opencanary.tac
sudo cp ./opencanary/build/scripts-3.9/opencanary.tac /usr/local/bin/opencanary.tac

# Create a sample config file
opencanaryd --copyconfig

# Start OpenCanary
opencanaryd --start

# Change the SSH port
SSH_PORT="65522"
sudo sed -i "s/#Port 22/Port ${SSH_PORT}/" /etc/ssh/sshd_config
whiptail --title "SSH Port Changed" --yesno "SSH port has been changed to ${SSH_PORT}. Device should reboot the first time you run this script to install recent changes. If you are re-running this script, press no to skip this reboot. Do you want to reboot the system?" 10 60

if [ $? -eq 0 ]; then
    sudo reboot -n
else
    echo "Skipping reboot."
fi

# Install Samba
sudo apt install samba samba-common-bin

# Rename the smb configuration file
sudo mv /etc/samba/smb.conf /etc/samba/smb.conf_backup

# Create a new configuration file
# Define variables
SMB_CONF_FILE="/etc/samba/smb.conf"
SMB_CONF_CONTENT="[global]
workgroup = OFFICVLAN
server string = Synology Backup
netbios name = SYNOLOGY
dns proxy = no
log file = /var/log/samba/log.all
log level = 0
vfs object = full_audit
full_audit:prefix = %U|%I|%i|%m|%S|%L|%R|%a|%T|%D
full_audit:success = pread
full_audit:failure = none
full_audit:facility = local7
full_audit:priority = notice
max log size = 100
panic action = /usr/share/samba/panic-action %d
#samba 4
server role = standalone server
#samba 3
#security = user
passdb backend = tdbsam
obey pam restrictions = yes
unix password sync = no
map to guest = bad user
usershare allow guests = yes
[myshare]
comment = Local Backup
path = /home/backups
guest ok = yes
read only = yes
browseable = yes"

# Check if the configuration file already exists
if [ -f $SMB_CONF_FILE ]; then
  echo "Configuration file already exists. Skipping creation."
else
  # Create the configuration file and add the provided contents
  echo "$SMB_CONF_CONTENT" | sudo tee $SMB_CONF_FILE > /dev/null
  echo "Configuration file created at $SMB_CONF_FILE."
fi

# Install CUPS
sudo apt install cups

# Autostart OpenCanary
read -p "Enter your gmail address (to receive alerts to): " gmail
read -p "Enter your app password (available at Security > App Passwords in google account): " apppassword
# Define variables
OC_SERV_FILE="/etc/opencanaryd/opencanary.conf"
OC_SERV_CONTENT='{
"device.node_id": "opencanary-1",
"ip.ignorelist": [ ],
"git.enabled": false,
"git.port" : 9418,
"ftp.enabled": true,
"ftp.port": 21,
"ftp.banner": "FTP server ready",
"http.banner": "Apache/2.2.22 (Ubuntu)",
"http.enabled": true,
"http.port": 80,
"http.skin": "nasLogin",
"httpproxy.enabled" : false,
"httpproxy.port": 8080,
"httpproxy.skin": "squid",
"logger": {
"class": "PyLogger",
"kwargs": {
"formatters": {
"plain": {
"format": "%(message)s"
},
"syslog_rfc": {
"format": "opencanaryd[%(process)-5s:%(thread)d]: %(name)s %(levelname)-5s %(message)s"
}
},
"handlers": {
"console": {
"class": "logging.StreamHandler",
"stream": "ext://sys.stdout"
},
"file": {
"class": "logging.FileHandler",
"filename": "/var/tmp/opencanary.log"
},
"SMTP": {
"class": "logging.handlers.SMTPHandler",
"mailhost": ["smtp.gmail.com", 587],
"fromaddr": "myalerts@gmail.com",
"toaddrs" : ["${gmail}"],
"subject" : "OpenCanary Alert",
"credentials" : ["${gmail}", "${apppassword}"],
"secure" : []
}
}
}
},
"portscan.enabled": true,
"portscan.ignore_localhost": false,
"portscan.logfile":"/var/log/kern.log",
"portscan.synrate": 5,
"portscan.nmaposrate": 5,
"portscan.lorate": 3,
"smb.auditfile": "/var/log/samba/log.all",
"smb.enabled": true,
"mysql.enabled": false,
"mysql.port": 3306,
"mysql.banner": "5.5.43-0ubuntu0.14.04.1",
"ssh.enabled": false,
"ssh.port": 22,
"ssh.version": "SSH-2.0-OpenSSH_5.1p1 Debian-4",
"redis.enabled": false,
"redis.port": 6379,
"rdp.enabled": false,
"rdp.port": 3389,
"sip.enabled": false,
"sip.port": 5060,
"snmp.enabled": false,
"snmp.port": 161,
"ntp.enabled": false,
"ntp.port": 123,
"tftp.enabled": false,
"tftp.port": 69,
"tcpbanner.maxnum":10,
"tcpbanner.enabled": false,
"tcpbanner_1.enabled": false,
"tcpbanner_1.port": 8001,
"tcpbanner_1.datareceivedbanner": "",
"tcpbanner_1.initbanner": "",
"tcpbanner_1.alertstring.enabled": false,
"tcpbanner_1.alertstring": "",
"tcpbanner_1.keep_alive.enabled": false,
"tcpbanner_1.keep_alive_secret": "",
"tcpbanner_1.keep_alive_probes": 11,
"tcpbanner_1.keep_alive_interval":300,
"tcpbanner_1.keep_alive_idle": 300,
"telnet.enabled": false,
"telnet.port": 23,
"telnet.banner": "",
"telnet.honeycreds": [
{
"username": "admin",
"password": "$pbkdf2-sha512$12020$bG1NaX3xvjdGyBlj7R22Xw$dGrmBqqWa1okTCpN4QEmeo9j5DuV2u1EuVFD8Di0GxNiM64To5O/Y66f7SASvnQr8.LTzqTm6awC8Kj/aGKvwA"
},
{
"username": "admin",
"password": "admin1"
}
],
"mssql.enabled": false,
"mssql.version": "2012",
"mssql.port":1433,
"vnc.enabled": false,
"vnc.port":5000
}
}'

# Check if the configuration file already exists
if [ -f $OC_SERV_FILE ]; then
  read -p "Configuration file already exists. Do you want to overwrite it? (y/n): " overwrite
  if [ "$overwrite" = "y" ] || [ "$overwrite" = "Y" ]; then
    # Create the configuration file and add the provided contents
    echo "$OC_SERV_CONTENT" | sudo tee $OC_SERV_FILE > /dev/null
    echo "Configuration file overwritten at $OC_SERV_FILE."
  else
    echo "Skipping file creation."
  fi
else
  # Create the configuration file and add the provided contents
  echo "$OC_SERV_CONTENT" | sudo tee $OC_SERV_FILE > /dev/null
  echo "Configuration file created at $OC_SERV_FILE."
fi

# Enable the service
sudo systemctl enable opencanary.service
sudo systemctl start opencanary.service

# Check the service status
systemctl status opencanary.service

whiptail --title "OpenCanary Setup Complete" --msgbox "OpenCanary setup is now complete. Press enter to continue"


