import discord
from discord.ext import commands
from discord import app_commands
import json
import subprocess
from flask import Flask, jsonify, request
import threading

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

# Slash Command for creating a VPS
@bot.tree.command(name="create_vps", description="Create a new VPS")
async def create_vps(interaction: discord.Interaction, memory: int, cores: int, customer: str):
    if not is_admin(interaction):
        await interaction.response.send_message("You don't have permission to use this command.", ephemeral=True)
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
        await interaction.response.send_message(f"✅ VPS `{vps_id}` created for customer `{customer}`.", ephemeral=True)
    except Exception as e:
        await interaction.response.send_message(f"❌ Failed to create VPS: {str(e)}", ephemeral=True)

# Slash Command for setting storage per GB
@bot.tree.command(name="set_storage", description="Set the default storage per GB of RAM")
async def set_storage(interaction: discord.Interaction, ram_gb: int, per_storage_gb: float):
    if not is_owner(interaction):
        await interaction.response.send_message("You don't have permission to use this command.", ephemeral=True)
        return
    config["storage_per_gb"] = per_storage_gb
    save_config()
    await interaction.response.send_message(f"✅ Default storage set: {per_storage_gb}GB per {ram_gb}GB RAM.", ephemeral=True)

# Slash Command for suspending a VPS
@bot.tree.command(name="suspend_vps", description="Suspend a VPS")
async def suspend_vps(interaction: discord.Interaction, vps_id: str, reason: str):
    if not is_admin(interaction):
        await interaction.response.send_message("You don't have permission to use this command.", ephemeral=True)
        return
    vps = config["vps"].get(vps_id)
    if not vps:
        await interaction.response.send_message("❌ VPS not found.", ephemeral=True)
        return

    # Suspend VPS
    try:
        subprocess.run(["virsh", "suspend", vps_id], check=True)
        vps["status"] = "suspended"
        save_config()

        # Notify
        customer = vps["customer"]
        await interaction.response.send_message(f"✅ VPS `{vps_id}` suspended. Reason: {reason}", ephemeral=True)
        channel = discord.utils.get(bot.get_all_channels(), name=config["notification_channel"])
        if channel:
            await channel.send(f"🚨 VPS `{vps_id}` owned by `{customer}` suspended. Reason: {reason}")
    except Exception as e:
        await interaction.response.send_message(f"❌ Failed to suspend VPS: {str(e)}", ephemeral=True)

# Flask web interface
app = Flask(__name__)

@app.route("/vps", methods=["GET"])
def get_vps():
    return jsonify(config["vps"])

@app.route("/vps/<vps_id>", methods=["GET"])
def get_vps_info(vps_id):
    vps = config["vps"].get(vps_id)
    if not vps:
        return jsonify({"error": "VPS not found"}), 404
    return jsonify(vps)

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

# Start both Flask and Discord bot in separate threads
def run_flask():
    # Start Flask with use_reloader=False to avoid Flask reloading
    app.run(port=5000, use_reloader=False)

def run_bot():
    bot.run(config["discord_token"])

if __name__ == "__main__":
    # Start the Flask web server and bot concurrently using threads
    flask_thread = threading.Thread(target=run_flask)
    flask_thread.daemon = True  # Make sure the Flask thread exits when the program exits
    flask_thread.start()

    # Start the bot in another thread
    bot_thread = threading.Thread(target=run_bot)
    bot_thread.start()
