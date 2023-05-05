#!/bin/bash

# Ensure script is run with sudo privileges
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run with sudo privileges."
    exit 1
fi

# Inform user of the installation process
whiptail --title "Installation" --msgbox "This script will update/upgrade 
all software, install and configure Cacti, and other necessary 
dependencies. Press OK to continue." 10 60

# Update and upgrade software
apt update && apt upgrade -y

# Install necessary packages
apt install -y librrds-perl libzip4 php php-json php-zip php7.3 php7.3-zip 
apache2 libapache2-mod-php7.3 mysql-server php-mysql nmap snmp snmpd 
rrdtool cacti

# Get Raspberry Pi's IP address
RASPI_IP=$(hostname -I | awk '{print $1}')

# Inform user to complete Cacti installation
whiptail --title "Cacti Installation" --msgbox "Please open your browser 
and navigate to http://${RASPI_IP}/cacti to complete the Cacti 
installation. After finishing the installation, return to this script and 
press OK to continue." 12 60

# Create database and grant privileges
mysql -e "CREATE DATABASE cacti; GRANT ALL PRIVILEGES ON cacti.* TO 
cactiuser@'localhost' IDENTIFIED BY 'cactipass'; FLUSH PRIVILEGES;"

# Configure Cacti credentials
cat > /usr/share/cacti/site/include/config.php <<EOL
<?php
\$database_type = 'mysql';
\$database_default = 'cacti';
\$database_hostname = 'localhost';
\$database_username = 'cactiuser';
\$database_password = 'cactipass';
\$database_port = '3306';
\$database_ssl = false;
\$database_ssl_key = '';
\$database_ssl_cert = '';
\$database_ssl_ca = '';
?>
EOL

# Enable PHP in Apache
cd /etc/apache2/mods-enabled
ln -s ../mods-available/php7.3.conf php7.3.conf
ln -s ../mods-available/php7.3.load php7.3.load

# Configure Cacti in Apache
cat > /etc/apache2/sites-enabled/cacti.conf <<EOL
Alias /cacti /usr/share/cacti/site
<Directory /usr/share/cacti/site>
<IfModule mod_authz_core.c>
    # httpd 2.4
    Require all granted
</IfModule>
</Directory>
EOL

# Restart Apache
systemctl restart apache2

# Direct user to Cacti URL
whiptail --title "Installation Complete" --msgbox "The installation is 
complete. Please open your browser and navigate to 
http://${RASPI_IP}/cacti to access Cacti." 10 60

