#!/bin/bash

# Welcome message
echo "Welcome to the KVM VPS Bot Installer!"
echo "This script will install Python, set up a virtual environment, and configure the bot."
echo ""

# Function to check and install Python 3 if necessary
install_python() {
    echo "Checking for Python 3 installation..."
    if ! command -v python3 &> /dev/null
    then
        echo "Python 3 is not installed. Installing Python 3..."
        sudo apt update
        sudo apt install -y python3 python3-venv python3-pip
    else
        echo "Python 3 is already installed."
    fi
}

# Install Python if necessary
install_python

# Install necessary packages
echo "Installing required packages..."
sudo apt install -y git

# Clone the GitHub repository containing the bot scripts
echo "Cloning the repository containing bot.py and web.py..."
git clone https://github.com/Sharpinte/Vpsbot.git /root/Vpsbot

# Navigate to the bot directory
cd /root/Vpsbot

# Create a virtual environment
echo "Setting up a Python virtual environment..."
python3 -m venv venv

# Activate the virtual environment
echo "Activating the virtual environment..."
source venv/bin/activate

# Upgrade pip within the virtual environment
echo "Upgrading pip to the latest version..."
pip install --upgrade pip

# Install Python dependencies
echo "Installing Python dependencies..."
pip install -r requirements.txt || { echo "Failed to install Python dependencies. Exiting."; deactivate; exit 1; }

# Prompt for bot configuration
echo "Please enter the configuration details for the bot."
read -p "Enter your Discord Bot Token: " DISCORD_TOKEN
read -p "Enter the Owner's Discord User ID: " OWNER_ID
read -p "Enter Admin Discord User IDs (comma-separated): " ADMIN_IDS
read -p "Enter the notification channel name (e.g., 'vps-alerts'): " NOTIFICATION_CHANNEL
read -p "Enter default storage per GB of RAM (e.g., 2.5): " STORAGE_PER_GB
read -p "Enter max RAM usage percentage before suspension (e.g., 90): " MAX_RAM_USAGE
read -p "Enter max CPU usage percentage before suspension (e.g., 90): " MAX_CPU_USAGE
read -p "Enter the max RAM (in GB) for all VPS combined (e.g., 64): " MAX_RAM
read -p "Enter the max CPU cores for all VPS combined (e.g., 32): " MAX_CPU
read -p "Enter the max storage (in GB) for all VPS combined (e.g., 1000): " MAX_STORAGE

# Create the config.json file
echo "Creating the configuration file (config.json)..."
cat <<EOF > config.json
{
    "discord_token": "$DISCORD_TOKEN",
    "owners": ["$OWNER_ID"],
    "admins": [${ADMIN_IDS//,/\", \"}],
    "vps": {},
    "storage_per_gb": $STORAGE_PER_GB,
    "anti_crypto": {
        "max_ram_usage": $MAX_RAM_USAGE,
        "max_cpu_usage": $MAX_CPU_USAGE
    },
    "notification_channel": "$NOTIFICATION_CHANNEL",
    "max_resources": {
        "ram": $MAX_RAM,
        "cpu": $MAX_CPU,
        "storage": $MAX_STORAGE
    }
}
EOF

# Final message
echo ""
echo "Installation complete! Your configuration has been saved to config.json."
echo "To run the bot, activate the virtual environment and start the bot:"
echo "    source venv/bin/activate"
echo "    python bot.py"
echo ""
echo "If you want to enable the web interface, run:"
echo "    python web.py"
