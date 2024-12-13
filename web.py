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
