#!/bin/bash

# Welcome message
echo "Welcome to the KVM VPS Bot Installer!"
echo "This script will help you set up the bot and its configuration."
echo ""

# Prompt for bot token
read -p "Enter your Discord Bot Token: " DISCORD_TOKEN

# Prompt for owner ID
read -p "Enter the Owner's Discord User ID (the bot owner): " OWNER_ID

# Prompt for admin IDs (optional)
read -p "Enter Admin Discord User IDs (comma-separated, or leave blank if none): " ADMIN_IDS

# Prompt for the notification channel name
read -p "Enter the name of the Discord channel for notifications (e.g., 'vps-alerts'): " NOTIFICATION_CHANNEL

# Ask for storage settings
read -p "Enter default storage per GB of RAM (e.g., 2.5): " STORAGE_PER_GB

# Ask for anti-crypto thresholds
read -p "Enter the max RAM usage percentage before suspension (e.g., 90): " MAX_RAM_USAGE
read -p "Enter the max CPU usage percentage before suspension (e.g., 90): " MAX_CPU_USAGE

# Ask for max resource caps
read -p "Enter the max RAM (in GB) for all VPS combined (e.g., 64): " MAX_RAM
read -p "Enter the max CPU cores for all VPS combined (e.g., 32): " MAX_CPU
read -p "Enter the max storage (in GB) for all VPS combined (e.g., 1000): " MAX_STORAGE

# Create `config.json`
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

# Install Python dependencies
echo "Installing required Python dependencies..."
pip install -r requirements.txt

# Success message
echo ""
echo "Installation complete! Your configuration has been saved to config.json."
echo "You can now run the bot using: python bot.py"
echo "If you want to enable the web interface, run: python web.py"
echo ""
