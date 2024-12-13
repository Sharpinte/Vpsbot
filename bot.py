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
