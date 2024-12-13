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

# Create a virtual environment
echo "Setting up a Python virtual environment..."
python3 -m venv venv

# Activate the virtual environment
echo "Activating the virtual environment..."
source venv/bin/activate

# Upgrade pip within the virtual environment
echo "Upgrading pip to the latest version..."
pip install --upgrade pip

# Check if requirements.txt exists, if not, create it
if [ ! -f requirements.txt ]; then
    echo "Creating requirements.txt..."
    echo -e "discord.py\nFlask" > requirements.txt
fi

# Install Python dependencies
echo "Installing Python dependencies..."
pip install -r requirements.txt || { echo "Failed to install Python dependencies. Exiting."; deactivate; exit 1; }

# Prompt for bot configuration
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

# Install the bot.py and web.py scripts
echo "Creating bot.py script..."
cat <<EOF > bot.py
import discord
from discord.ext import commands
import json
import subprocess
from flask import Flask, jsonify

# Load configuration
with open("config.json", "r") as f:
    config = json.load(f)

# Discord bot setup
intents = discord.Intents.all()
bot = commands.Bot(command_prefix="/", intents=intents)

# Utility functions
def is_owner(ctx):
    return str(ctx.author.id) in config["owners"]

def is_admin(ctx):
    return str(ctx.author.id) in config["admins"]

def save_config():
    with open("config.json", "w") as f:
        json.dump(config, f, indent=4)

# Check anti-crypto usage
async def check_anti_crypto(vps_id, ram_usage, cpu_usage):
    vps = config["vps"].get(vps_id)
    if not vps:
        return

    # Suspend VPS if limits exceeded
    if ram_usage > config["anti_crypto"]["max_ram_usage"] or cpu_usage > config["anti_crypto"]["max_cpu_usage"]:
        await suspend_vps(None, vps_id, reason="Suspicious crypto-mining behavior detected.")
        owner_id = vps["customer"]
        channel = discord.utils.get(bot.get_all_channels(), name=config["notification_channel"])
        if channel:
            await channel.send(f"⚠️ VPS `{vps_id}` owned by <@{owner_id}> suspended due to high resource usage.")

# Commands
@bot.command()
async def create_vps(ctx, memory: int, cores: int, customer: str):
    if not is_admin(ctx):
        await ctx.send("You don't have permission to use this command.")
        return

    try:
        # Calculate storage based on memory
        storage = memory * config["storage_per_gb"]
        vps_id = f"vps-{customer}-{len(config['vps']) + 1}"

        # Example: Create VPS (you can replace this with your actual KVM logic)
        subprocess.run([
            "virt-install",
            "--name", vps_id,
            "--memory", str(memory),
            "--vcpus", str(cores),
            "--disk", f"size={storage}",
            "--os-variant", "ubuntu20.04",
            "--network", "default",
        ], check=True)

        # Save VPS to config
        config["vps"][vps_id] = {
            "id": vps_id,
            "memory": memory,
            "cores": cores,
            "storage": storage,
            "customer": customer,
            "status": "running"
        }
        save_config()
        await ctx.send(f"✅ VPS `{vps_id}` created for customer `{customer}`.")
    except Exception as e:
        await ctx.send(f"❌ Failed to create VPS: {str(e)}")

@bot.command()
async def set_storage(ctx, ram_gb: int, per_storage_gb: float):
    if not is_owner(ctx):
        await ctx.send("You don't have permission to use this command.")
        return
    config["storage_per_gb"] = per_storage_gb
    save_config()
    await ctx.send(f"✅ Default storage set: {per_storage_gb}GB per {ram_gb}GB RAM.")

@bot.command()
async def suspend_vps(ctx, vps_id: str, *, reason: str):
    if not is_admin(ctx):
        await ctx.send("You don't have permission to use this command.")
        return
    vps = config["vps"].get(vps_id)
    if not vps:
        await ctx.send("❌ VPS not found.")
        return

    # Suspend VPS
    try:
        subprocess.run(["virsh", "suspend", vps_id], check=True)
        vps["status"] = "suspended"
        save_config()

        # Notify
        customer = vps["customer"]
        await ctx.send(f"✅ VPS `{vps_id}` suspended. Reason: {reason}")
        channel = discord.utils.get(bot.get_all_channels(), name=config["notification_channel"])
        if channel:
            await channel.send(f"🚨 VPS `{vps_id}` owned by `{customer}` suspended. Reason: {reason}")
    except Exception as e:
        await ctx.send(f"❌ Failed to suspend VPS: {str(e)}")

# Add additional commands here...

# Run the bot
bot.run(config["discord_token"])
EOF

echo "Creating web.py script..."
cat <<EOF > web.py
from flask import Flask, jsonify, request
import json

app = Flask(__name__)

# Load configuration
with open("config.json", "r") as f:
    config = json.load(f)

# Endpoint to show all VPS
@app.route("/vps", methods=["GET"])
def get_vps():
    return jsonify(config["vps"])

# Endpoint to get specific VPS
@app.route("/vps/<vps_id>", methods=["GET"])
def get_vps_info(vps_id):
    vps = config["vps"].get(vps_id)
    if not vps:
        return jsonify({"error": "VPS not found"}), 404
    return jsonify(vps)

# Endpoint to modify resource limits (admin only)
@app.route("/set-cap", methods=["POST"])
def set_cap():
    data = request.json
    config["max_resources"] = {
        "ram": data.get("ram"),
        "cpu": data.get("cpu"),
        "storage": data.get("storage")
    }
    save_config()
    return jsonify({"message": "Resource caps updated."})

# Save configuration
def save_config():
    with open("config.json", "w") as f:
        json.dump(config, f, indent=4)

# Run the server
if __name__ == "__main__":
    app.run(port=5000)
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
