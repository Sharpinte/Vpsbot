#!/bin/bash

# Function to display ASCII art
display_ascii_art() {
    echo "VPS BOT"
    echo "---------------------------"
    echo ".___ _____________________________.____      ____   ______________  _________ __________ ___________________"
    echo "|   |\      \__    ___/\_   _____/|    |     \   \ /   /\______   \/   _____/ \______   \\_____  \__    ___/"
    echo "|   |/   |   \|    |    |    __)_ |    |      \   Y   /  |     ___/\_____  \   |    |  _/ /   |   \|    |   "
    echo "|   /    |    \    |    |        \|    |___    \     /   |    |    /        \  |    |   \/    |    \    |   "
    echo "|___\____|__  /____|   /_______  /|_______ \    \___/    |____|   /_______  /  |______  /\_______  /____|   "
    echo "            \/                 \/         \/                              \/          \/         \/         " 
    echo "---------------------------"
}

# Function to check and install Python 3
install_python() {
    echo "Checking for Python 3 installation..."

    if ! command -v python3 &> /dev/null; then
        echo "Python 3 is not installed. Installing Python 3..."
        if command -v sudo &> /dev/null; then
            sudo apt update
            sudo apt install -y python3 python3-venv python3-pip
        else
            echo "Error: 'sudo' command not found. Please install Python 3 manually and re-run the script."
            exit 1
        fi
    else
        echo "Python 3 is already installed."
    fi

    if ! command -v python &> /dev/null; then
        echo "Creating symlink for 'python' to point to 'python3'..."
        if command -v sudo &> /dev/null; then
            sudo ln -sf /usr/bin/python3 /usr/bin/python
        else
            echo "Error: 'sudo' command not found. Please create the symlink manually: 'ln -sf /usr/bin/python3 /usr/bin/python'."
            exit 1
        fi
    fi
}

# Function to download bot.py
download_bot() {
    echo "Downloading bot.py..."
    wget -O bot.py https://raw.githubusercontent.com/Sharpinte/Vpsbot/main/bot.py
}

# Function to download web.py
download_web() {
    echo "Downloading web.py..."
    wget -O web.py https://raw.githubusercontent.com/Sharpinte/Vpsbot/main/web.py
}

# Function to install bot and web server
install_bot_and_web() {
    install_python
    python3 -m venv venv
    source venv/bin/activate
    download_bot
    download_web

    echo "Installing Python dependencies..."
    pip install --upgrade pip
    echo -e "discord.py\nFlask" > requirements.txt
    pip install -r requirements.txt

    echo "Enter your Discord Bot Token: "
    read DISCORD_TOKEN
    echo "Enter the Owner's Discord User ID: "
    read OWNER_ID
    echo "Enter Admin Discord User IDs (comma-separated): "
    read ADMIN_IDS
    echo "Enter the notification channel name (e.g., 'vps-alerts'): "
    read NOTIFICATION_CHANNEL

    ADMIN_IDS_ARRAY=$(echo "$ADMIN_IDS" | awk -F',' '{for(i=1; i<=NF; i++) $i="\""$i"\""} 1' OFS=', ')

    echo "Creating the configuration file (config.json)..."
    cat <<EOF > config.json
{
    "discord_token": "$DISCORD_TOKEN",
    "owners": ["$OWNER_ID"],
    "admins": [$ADMIN_IDS_ARRAY],
    "vps": {},
    "notification_channel": "$NOTIFICATION_CHANNEL"
}
EOF

    python bot.py &
    python web.py &

    echo "Installation complete!"
}

# Function to install bot only
install_bot_only() {
    install_python
    python3 -m venv venv
    source venv/bin/activate
    download_bot

    echo "Installing Python dependencies for bot..."
    pip install --upgrade pip
    echo -e "discord.py" > requirements.txt
    pip install -r requirements.txt

    echo "Enter your Discord Bot Token: "
    read DISCORD_TOKEN
    echo "Enter the Owner's Discord User ID: "
    read OWNER_ID
    echo "Enter Admin Discord User IDs (comma-separated): "
    read ADMIN_IDS
    echo "Enter the notification channel name (e.g., 'vps-alerts'): "
    read NOTIFICATION_CHANNEL

    ADMIN_IDS_ARRAY=$(echo "$ADMIN_IDS" | awk -F',' '{for(i=1; i<=NF; i++) $i="\""$i"\""} 1' OFS=', ')

    echo "Creating the configuration file (config.json)..."
    cat <<EOF > config.json
{
    "discord_token": "$DISCORD_TOKEN",
    "owners": ["$OWNER_ID"],
    "admins": [$ADMIN_IDS_ARRAY],
    "vps": {},
    "notification_channel": "$NOTIFICATION_CHANNEL"
}
EOF

    python bot.py &
    echo "Bot installation complete!"
}

# Function to uninstall bot and web server
uninstall_bot_and_web() {
    echo "Uninstalling bot and web server..."
    pkill -f bot.py
    pkill -f web.py
    rm -rf venv
    rm -f config.json
    rm -f requirements.txt
    rm -f bot.py web.py
    echo "Uninstallation complete!"
}

# Function to update the script
update_script() {
    echo "Updating script..."
    SCRIPT_URL="https://raw.githubusercontent.com/Sharpinte/Vpsbot/main/install.sh"

    wget -O install.sh.new "$SCRIPT_URL"
    if [ $? -eq 0 ]; then
        mv install.sh.new install.sh
        chmod +x install.sh
        echo "Script updated successfully! Please re-run the script."
        exit 0
    else
        echo "Failed to update script. Please check your internet connection or the URL."
        rm -f install.sh.new
    fi
}

# Function to show the main menu
show_menu() {
    display_ascii_art
    echo "Please select an option:"
    echo "[1] Install bot only"
    echo "[2] Install web server + bot"
    echo "[3] Uninstall bot and web server"
    echo "[4] Update script"
    echo "[5] Exit"
    read -p "Enter your choice [1-5]: " choice
    case $choice in
        1) install_bot_only ;;
        2) install_bot_and_web ;;
        3) uninstall_bot_and_web ;;
        4) update_script ;;
        5) exit 0 ;;
        *) echo "Invalid choice. Please try again." ; show_menu ;;
    esac
}

# Run the menu system
show_menu
