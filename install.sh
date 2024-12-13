#!/bin/bash

# Function to display ASCII art
display_ascii_art() {
    echo "VPS BOT"
    echo "---------------------------"
    echo "    __   __    ____       "
    echo "   |  | |  |  / ___|___   "
    echo "   |  | |  | | |   / _ \  "
    echo "   |  |_|  | | |__| (_) | "
    echo "   |______|   \____\___/  "
    echo "---------------------------"
}

# Function to install Python if needed
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

# Function to clone the repository
git_clone_repo() {
    if [ ! -d "Vpsbot" ]; then
        echo "Cloning the repository from GitHub..."
        git clone https://github.com/Sharpinte/Vpsbot/
    else
        echo "Repository already cloned."
    fi
}

# Function to install bot and web server
install_bot_and_web() {
    git_clone_repo
    cd Vpsbot || exit

    # Create virtual environment
    python3 -m venv venv
    source venv/bin/activate

    # Install dependencies
    echo "Installing Python dependencies..."
    pip install --upgrade pip
    echo -e "discord.py\nFlask" > requirements.txt
    pip install -r requirements.txt

    # Prompt user for configuration
    echo "Enter your Discord Bot Token: "
    read DISCORD_TOKEN
    echo "Enter the Owner's Discord User ID: "
    read OWNER_ID
    echo "Enter Admin Discord User IDs (comma-separated): "
    read ADMIN_IDS
    echo "Enter the notification channel name (e.g., 'vps-alerts'): "
    read NOTIFICATION_CHANNEL

    # Create config.json file
    echo "Creating the configuration file (config.json)..."
    cat <<EOF > config.json
{
    "discord_token": "$DISCORD_TOKEN",
    "owners": ["$OWNER_ID"],
    "admins": [${ADMIN_IDS//,/\", \"}"],
    "vps": {},
    "notification_channel": "$NOTIFICATION_CHANNEL"
}
EOF

    # Start the bot and web server
    echo "Starting bot and web server..."
    python3 bot.py &
    python3 web.py &

    echo "Installation complete!"
}

# Function to install bot only
install_bot_only() {
    git_clone_repo
    cd Vpsbot || exit

    # Create virtual environment
    python3 -m venv venv
    source venv/bin/activate

    # Install dependencies
    echo "Installing Python dependencies for bot..."
    pip install --upgrade pip
    echo -e "discord.py" > requirements.txt
    pip install -r requirements.txt

    # Prompt user for configuration
    echo "Enter your Discord Bot Token: "
    read DISCORD_TOKEN
    echo "Enter the Owner's Discord User ID: "
    read OWNER_ID
    echo "Enter Admin Discord User IDs (comma-separated): "
    read ADMIN_IDS
    echo "Enter the notification channel name (e.g., 'vps-alerts'): "
    read NOTIFICATION_CHANNEL

    # Create config.json file
    echo "Creating the configuration file (config.json)..."
    cat <<EOF > config.json
{
    "discord_token": "$DISCORD_TOKEN",
    "owners": ["$OWNER_ID"],
    "admins": [${ADMIN_IDS//,/\", \"}"],
    "vps": {},
    "notification_channel": "$NOTIFICATION_CHANNEL"
}
EOF

    # Start the bot
    echo "Starting bot..."
    python3 bot.py &

    echo "Bot installation complete!"
}

# Function to install web server only
install_web_only() {
    git_clone_repo
    cd Vpsbot || exit

    # Create virtual environment
    python3 -m venv venv
    source venv/bin/activate

    # Install dependencies
    echo "Installing Python dependencies for web server..."
    pip install --upgrade pip
    echo -e "Flask" > requirements.txt
    pip install -r requirements.txt

    # Start the web server
    echo "Starting web server..."
    python3 web.py &

    echo "Web server installation complete!"
}

# Function to uninstall bot and web server
uninstall_bot_and_web() {
    echo "Uninstalling bot and web server..."

    # Stop running bot and web server if they are running
    pkill -f bot.py
    pkill -f web.py

    # Remove the virtual environment and configuration files
    rm -rf venv
    rm -f config.json
    rm -f requirements.txt

    # Remove installation scripts (install.sh, install.sh.x)
    rm -f install.sh install.sh.1 install.sh.2 install.sh.3

    # Remove the vpsbot folder
    rm -rf Vpsbot

    echo "Uninstallation complete!"
}

# Function to show the main menu
show_menu() {
    display_ascii_art
    echo "Please select an option:"
    echo "[1] Install bot only"
    echo "[2] Install web server + bot"
    echo "[3] Uninstall bot and web server"
    echo "[4] Exit"
    read -p "Enter your choice [1-4]: " choice
    case $choice in
        1) install_bot_only ;;
        2) install_bot_and_web ;;
        3) uninstall_bot_and_web ;;
        4) exit 0 ;;
        *) echo "Invalid choice. Please try again." ; show_menu ;;
    esac
}

# Run the menu system
show_menu
