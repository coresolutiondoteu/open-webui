import json
import subprocess

CONFIG_PATH = "/app/config.json"

def get_current_model():
    with open(CONFIG_PATH, "r") as f:
        config = json.load(f)
    return config["current_model"]

def switch_model(new_model):
    with open(CONFIG_PATH, "r") as f:
        config = json.load(f)

    if new_model not in config["available_models"]:
        return "Error: Model not found"

    # Stop current model (modify this for your LLM server)
    subprocess.run(["pkill", "-f", get_current_model()], check=False)

    # Start new model (modify this command based on LLM server)
    subprocess.Popen(["ollama", "run", new_model], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    # Update config file
    config["current_model"] = new_model
    with open(CONFIG_PATH, "w") as f:
        json.dump(config, f)

    return f"Switched to {new_model}"