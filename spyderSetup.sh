#!/bin/bash

# Define required imports
REQUIRED_PACKAGES=(
  python3-pip
  libatlas-base-dev
  git
)

# Function to confirm user consent
function confirm() {
  whiptail --title "Confirmation" --yesno "${1:-Installing and Configuring Spyder-RPi setup. Are you sure you wish to proceed?}" 10 50
  return $?
}

# Function to display a message and wait for user input
function message() {
  whiptail --title "Message" --msgbox "$1" 10 50
  return $?
}

# Function to get user input
function input() {
  whiptail --title "Input" --inputbox "$1" 10 50 3>&1 1>&2 2>&3
}

# Update and upgrade the system
message "Updating system..."
sudo apt update
  sudo apt full-upgrade -y


# Install required packages
message "Installing required packages..."
for package in "${REQUIRED_PACKAGES[@]}"; do
  if dpkg-query -W "$package" >/dev/null 2>&1; then
    message "$package is already installed."
  else
    if confirm "Ready to install $package?"; then
      sudo apt install -y "$package"
    fi
  fi
done

# Create a new non-privileged user
message "Creating a new non-privileged user..."
new_username=$(input "Enter a username for the new non-privileged user:")
sudo adduser --gecos "" "$new_username"
sudo usermod -aG sudo "$new_username"

# Switch to the new user and continue the Cowrie installation process
message "Switching to the new user and continuing the Cowrie installation process..."
sudo su - "$new_username" <<'EOF'
  # Install Cowrie
  message "Installing Cowrie..."
  if [ -d "cowrie" ]; then
    message "Cowrie directory already exists. Skipping clone."
  else
    git clone https://github.com/cowrie/cowrie.git
  fi
  cd cowrie

  # Install required Python packages
  message "Installing required Python packages..."
  pip3 install --user -r requirements.txt

  # Set up completion
  message "Setting up completion..."
  cp doc/examples/cowrie.cfg.dist cowrie.cfg
  
  #troubleshooting after runtime, to mitigate compatibility errors
  cd /bin/cowrie
  sed -i 's/twistd/twistd3/g' start.sh

  # Setup scripts to run on boot
  message "Setting up scripts to run on boot..."
  SCRIPTS=("fcm-monitor-db.py" "fcm-monitor-notifications.py" "network_device_scan_periodic.py")
  for script in "${SCRIPTS[@]}"; do
    if [ -f "$script" ]; then
      script_name="${script%.*}"
      sudo tee /etc/systemd/system/"$script_name".service <<EOL >/dev/null
[Unit]
Description=$script_name service
After=network.target

[Service]
User=$new_username
WorkingDirectory=$(pwd)
ExecStart=/usr/bin/python3 $(pwd)/$script
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOL
      sudo systemctl daemon-reload
      sudo systemctl enable "$script_name"
      sudo systemctl start "$script_name"
    else
      message "Script $script not found. Skipping."
    fi
  done
EOF

# Done
message "start cowrie by running   /bin/cowrie start"
message "Installation completed!"
