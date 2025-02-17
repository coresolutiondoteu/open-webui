Sure! Below is a PowerShell script that you can run on your Windows machine from an LXC container. This script will:  

1. Start the Docker service (if it's not already running).  
2. Navigate to the directory where your `docker-compose.yml` file is located.  
3. Run `docker-compose up -d` to start the containers in detached mode.  

### **Steps to Use:**
1. **Save the script** as `start_docker.ps1` on your Windows machine.  
2. **Enable PowerShell Remoting** on your Windows machine (if not already enabled) using:  
   ```powershell
   Enable-PSRemoting -Force
   ```
3. **Run the script remotely** from your LXC container using `ssh` or `winrm`.

---

### **PowerShell Script (`start_docker.ps1`)**
```powershell
# Check if Docker service is running, if not, start it
$service = Get-Service -Name "docker" -ErrorAction SilentlyContinue
if ($service -and $service.Status -ne "Running") {
    Write-Host "Starting Docker service..."
    Start-Service -Name "docker"
    Start-Sleep -Seconds 5  # Wait a bit for Docker to start
} else {
    Write-Host "Docker is already running."
}

# Define the path where docker-compose.yml is located
$composePath = "C:\path\to\your\docker-compose.yml"

# Check if the path exists
if (Test-Path $composePath) {
    Write-Host "Starting Docker Compose..."
    Set-Location (Split-Path -Path $composePath)
    docker-compose up -d
} else {
    Write-Host "Error: docker-compose.yml not found at $composePath"
}
```
---

### **Running the Script from LXC**  
From your LXC container (assuming you have SSH access to the Windows box), use:  

```bash
ssh username@windows-ip "powershell -ExecutionPolicy Bypass -File C:\path\to\start_docker.ps1"
```
OR  
If you are using **WinRM**, you can execute the script remotely using Python (with `pywinrm` library) or `ansible`.

Would you like a WinRM version as well?

Since you have nothing set up yet, let's go step by step. I'll cover:  

1. **How to securely enable remote execution from an LXC container to a Windows machine.**  
2. **How to configure the Windows machine properly.**  
3. **Security considerations.**  

## **Step 1: Decide on Remote Execution Method**  
There are two main ways to run commands on a Windows machine from an LXC container:  

### **1.1 Secure Method: SSH to Windows** (Recommended)  
- Windows 10/11 and Server 2019+ support OpenSSH natively.  
- **Pros:** Secure, easier to set up, minimal attack surface.  
- **Cons:** Requires setting up SSH on Windows.  

### **1.2 Alternative: WinRM (PowerShell Remoting)**  
- Uses Windows Remote Management (WinRM).  
- **Pros:** Can work with Windows authentication, integrates with Ansible.  
- **Cons:** More complex to secure, might expose Windows to unnecessary risk.  

I **strongly recommend SSH** over WinRM for security and simplicity.

---

## **Step 2: Set Up SSH on Windows**  
1. **Install OpenSSH Server on Windows**  
   Open PowerShell as Administrator and run:  
   ```powershell
   Add-WindowsFeature -Name OpenSSH-Server
   ```
   Then, start and enable the SSH service:  
   ```powershell
   Start-Service sshd
   Set-Service -Name sshd -StartupType Automatic
   ```

2. **Allow SSH in Windows Firewall**  
   ```powershell
   New-NetFirewallRule -Name "SSH" -DisplayName "SSH" -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
   ```

3. **Create an SSH User** (if needed)  
   If you don’t want to use an existing Windows user, create one:  
   ```powershell
   net user dockeradmin StrongPassword123! /add
   ```

4. **Set Up SSH Key Authentication (More Secure)**  
   On your **LXC container**, generate an SSH key:  
   ```bash
   ssh-keygen -t rsa -b 4096 -f ~/.ssh/windows_ssh_key
   ```
   Copy the public key to the Windows box:  
   ```bash
   ssh-copy-id -i ~/.ssh/windows_ssh_key.pub dockeradmin@windows-ip
   ```

5. **Test SSH Connection**  
   From your LXC container, run:  
   ```bash
   ssh -i ~/.ssh/windows_ssh_key dockeradmin@windows-ip "hostname"
   ```
   If it prints the Windows hostname, SSH is working!

---

## **Step 3: Deploy the Script on Windows**  
Now, create the PowerShell script on Windows to start Docker and your containers:  

### **PowerShell Script (`C:\scripts\start_docker.ps1`)**
```powershell
# Ensure Docker is running
$service = Get-Service -Name "docker" -ErrorAction SilentlyContinue
if ($service -and $service.Status -ne "Running") {
    Write-Host "Starting Docker service..."
    Start-Service -Name "docker"
    Start-Sleep -Seconds 5
} else {
    Write-Host "Docker is already running."
}

# Start Docker Compose
$composePath = "C:\path\to\your\docker-compose.yml"
if (Test-Path $composePath) {
    Write-Host "Starting Docker Compose..."
    Set-Location (Split-Path -Path $composePath)
    docker-compose up -d
} else {
    Write-Host "Error: docker-compose.yml not found at $composePath"
}
```

---

## **Step 4: Run the Script from LXC**  
From your LXC container, use:  
```bash
ssh -i ~/.ssh/windows_ssh_key dockeradmin@windows-ip "powershell -ExecutionPolicy Bypass -File C:\scripts\start_docker.ps1"
```

---

## **Security Considerations**
- **Use SSH keys instead of passwords.**  
- **Restrict SSH access** to only your LXC container's IP.  
- **Disable password authentication** in SSH by editing `C:\ProgramData\ssh\sshd_config` and setting:  
  ```
  PasswordAuthentication no
  ```
- **Run the script as a non-admin user** with only Docker permissions.  

---

### **Next Steps**
- Do you need help configuring SSH further?  
- Do you want to automate the script execution (e.g., via cron job on LXC)?

To run the script with **only Docker permissions** (without full admin rights), you need to:  

1. **Create a non-admin user** on Windows.  
2. **Add the user to the "docker-users" group** (which allows managing Docker without admin).  
3. **Ensure the user can run the script via SSH without requiring elevation.**  

---

## **1. Create a Non-Admin User**  
Open **PowerShell as Administrator** and run:  
```powershell
net user dockeruser StrongPassword123! /add
```

This creates a new user **`dockeruser`** with the password **`StrongPassword123!`**. Change the password to something secure.

---

## **2. Add User to the "docker-users" Group**  
By default, only **Administrators** can use Docker. But Windows has a **"docker-users"** group for non-admin users. Add `dockeruser` to it:  

```powershell
Add-LocalGroupMember -Group "docker-users" -Member "dockeruser"
```

Then **restart your Windows machine** for this change to apply.  

---

## **3. Test Docker Access Without Admin Rights**  
Log in as `dockeruser` and test if it can run Docker commands.  

1. Switch to `dockeruser`:
   ```powershell
   runas /user:dockeruser cmd
   ```
2. Try running Docker:
   ```powershell
   docker ps
   ```
   If you see running containers (or an empty list), it’s working!

---

## **4. Allow the User to Run the Script via SSH**  
Now, make sure `dockeruser` can SSH into the Windows machine.  

1. **Enable SSH for `dockeruser`**  
   Open `C:\ProgramData\ssh\sshd_config` and allow the user:
   ```
   AllowUsers dockeruser
   ```
2. Restart the SSH service:
   ```powershell
   Restart-Service sshd
   ```

3. **Copy your SSH key** to the user’s profile:  
   On your **LXC container**, run:  
   ```bash
   ssh-copy-id -i ~/.ssh/windows_ssh_key.pub dockeruser@windows-ip
   ```

4. **Test SSH access**:  
   ```bash
   ssh -i ~/.ssh/windows_ssh_key dockeruser@windows-ip "docker ps"
   ```

---

## **5. Run the Script Securely from LXC**  
Now, execute your script using the non-admin user:  

```bash
ssh -i ~/.ssh/windows_ssh_key dockeruser@windows-ip "powershell -ExecutionPolicy Bypass -File C:\scripts\start_docker.ps1"
```

This way:  
✅ The user **cannot modify system files**  
✅ The user **cannot install software**  
✅ The user **can only control Docker**  

---

### **Final Security Enhancements**
- Disable password SSH login (`PasswordAuthentication no` in `sshd_config`).  
- Restrict the user to LXC’s IP (`Match User dockeruser` in `sshd_config`).  
- Remove unneeded permissions (`icacls C:\scripts\start_docker.ps1 /inheritance:r`).  

Now you have a **secure, limited-access user** who can only run Docker!  

Would you like any additional security configurations?

You're absolutely right—being in the `docker-users` group allows the user to control **all** containers, which could be a security risk. If you want to **restrict the user to only specific containers or actions**, we need a more controlled approach.  

## **Solutions to Restrict Docker Access**  
Here are a few options to limit what the user can do:  

### **1. Use "docker context" to Restrict Access to Specific Containers**
You can create a **separate Docker context** with limited permissions and configure the user to use it instead of full Docker access.  

#### **Steps:**
1. **Create a Custom Docker API with Restricted Access**  
   Run Docker with restricted permissions (e.g., allow only certain containers):  
   ```powershell
   dockerd -H tcp://127.0.0.1:2376 --group docker-limited
   ```
   This creates an **alternative** Docker daemon API that listens on a different port.  

2. **Create a User Group with Limited Access**  
   ```powershell
   New-LocalGroup -Name "docker-limited" -Description "Limited Docker Access"
   Add-LocalGroupMember -Group "docker-limited" -Member "dockeruser"
   ```

3. **Force the User to Use the Limited API**  
   On the **LXC container**, configure SSH so that when `dockeruser` logs in, they only have access to the restricted Docker API:  
   ```bash
   export DOCKER_HOST=tcp://windows-ip:2376
   ```

Now, `dockeruser` can only interact with containers running under that specific Docker instance.

---

### **2. Use Docker RBAC with a Reverse Proxy (Advanced)**  
Since **Docker by default doesn’t support fine-grained permissions**, you can enforce **role-based access control (RBAC)** using a reverse proxy like **Traefik** or **Nginx** to filter Docker API requests.  

#### **Steps:**
1. **Run the Docker API behind Nginx**  
   Configure **Nginx** to allow only specific `docker` commands for `dockeruser`.  
   
   Example Nginx rule to **block `docker rm` but allow `docker start` and `docker ps`**:
   ```nginx
   location /v1.41/containers/ {
       proxy_pass http://localhost:2375;
       if ($request_method = DELETE) {
           return 403;
       }
   }
   ```

2. **Expose Only the Allowed Commands**  
   - Allow: `docker start`, `docker ps`  
   - Block: `docker rm`, `docker rmi`, `docker exec`  

Now, even though `dockeruser` has access to Docker, they **cannot delete or modify containers**.

---

### **3. Use "sudo-like" Permissions with `doas` on Windows**
Another option is to allow `dockeruser` to run **only specific commands** via an **elevated "doas" script** (like `sudo` on Linux).  

#### **Steps:**
1. Install **doas for Windows**:  
   Download [`doas.exe`](https://github.com/DarthSpock/doas-windows) and place it in `C:\Windows\System32`.  

2. **Configure Allowed Commands** (`C:\ProgramData\doas.conf`):  
   ```
   permit dockeruser as administrator cmd /c docker start my_container
   ```

3. **Modify Your Script to Use `doas`**  
   Change `start_docker.ps1` to:  
   ```powershell
   doas docker start my_container
   ```

Now, `dockeruser` **can only start a specific container** but **cannot run arbitrary Docker commands**.

---

## **Best Option for Your Case?**
| Method | Security Level | Complexity |
|--------|---------------|------------|
| **Docker Context with Restricted API** | Medium | Medium |
| **Reverse Proxy Filtering (Nginx/Traefik)** | High | Advanced |
| **Doas-like Command Control** | High | Simple |

**Recommended:** If you just need to allow `docker-compose up` but **block deleting/modifying containers**, use **option 3 (doas approach)**.  

Would you like help setting up one of these methods?

Great! Since you want the user to **only** start and stop a specific container (without modifying, deleting, or accessing other containers), we can implement a secure method using **Windows ACLs + a controlled PowerShell script**.  

### **Plan**
1. **Create a non-admin user** (`dockeruser`).  
2. **Restrict Docker permissions** so the user can only run `start` and `stop`.  
3. **Use a controlled PowerShell script** that only allows `docker start` and `docker stop`.  
4. **Prevent direct Docker access** so the user cannot run arbitrary commands.  

---

## **1. Create the Limited User**
If you haven't created `dockeruser` yet, run this in PowerShell as an **Administrator**:  
```powershell
net user dockeruser StrongPassword123! /add
```

Now add the user to the **docker-users** group:  
```powershell
Add-LocalGroupMember -Group "docker-users" -Member "dockeruser"
```

---

## **2. Restrict Direct Docker Access**
We want `dockeruser` to **only** execute a specific script and **not** run arbitrary Docker commands.

1. **Remove Docker CLI access for `dockeruser`**:  
   ```powershell
   icacls "C:\Program Files\Docker\Docker" /deny dockeruser:RX
   icacls "C:\Program Files\Docker\Docker\resources" /deny dockeruser:RX
   ```
   This prevents `dockeruser` from running `docker ps`, `docker rm`, etc.

2. **Allow only a controlled script**:  
   We will create a script that lets `dockeruser` **only** start or stop a specific container.

---

## **3. Create a Secure PowerShell Script**
This script ensures `dockeruser` can only start or stop **one specific container** (`my_container`).

### **Script: `C:\scripts\control_docker.ps1`**
```powershell
param (
    [ValidateSet("start", "stop")]
    [string]$action
)

$containerName = "my_container"

# Ensure the user can only start or stop the specific container
if ($action -eq "start") {
    Write-Host "Starting $containerName..."
    docker start $containerName
} elseif ($action -eq "stop") {
    Write-Host "Stopping $containerName..."
    docker stop $containerName
} else {
    Write-Host "Invalid action. Allowed: start, stop"
}
```
---

## **4. Set Permissions to Restrict Access**
Now, we ensure **only `dockeruser` can run this script** and **cannot modify it**.

1. **Set script ownership to `Administrator`**  
   Open PowerShell as **Administrator** and run:
   ```powershell
   icacls "C:\scripts\control_docker.ps1" /inheritance:r
   icacls "C:\scripts\control_docker.ps1" /grant dockeruser:RX
   icacls "C:\scripts\control_docker.ps1" /deny dockeruser:M
   ```
   - `RX` → Allows the user to read & execute.  
   - `M` → Denies modification (prevents editing the script).  

2. **Block PowerShell execution for `dockeruser` (except the script)**  
   ```powershell
   New-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows\PowerShell" -Name ExecutionPolicy -Value "Restricted" -PropertyType String
   ```
   This **blocks all PowerShell execution** unless explicitly allowed.

---

## **5. Allow SSH Execution of the Script**
Since `dockeruser` cannot run arbitrary commands, we allow **only** execution of this script via SSH.

Edit `C:\ProgramData\ssh\sshd_config` and **add this rule at the bottom**:  
```
Match User dockeruser
    ForceCommand powershell -ExecutionPolicy Bypass -File C:\scripts\control_docker.ps1
```
Then, **restart the SSH service**:  
```powershell
Restart-Service sshd
```

---

## **6. Run the Script from LXC**
Now, from your **LXC container**, you can securely start or stop the container:  

### **Start the container:**
```bash
ssh -i ~/.ssh/windows_ssh_key dockeruser@windows-ip "start"
```

### **Stop the container:**
```bash
ssh -i ~/.ssh/windows_ssh_key dockeruser@windows-ip "stop"
```

---

## **7. Final Security Check**
- **Docker CLI is blocked** for `dockeruser`.  
- **User can only start/stop `my_container`** (cannot delete or exec into it).  
- **PowerShell is restricted** (no arbitrary script execution).  
- **Only SSH execution of the script is allowed**.  

This setup ensures **maximum security while allowing only the required actions**.  

---

### **Would You Like Any Extra Restrictions?**  
For example:  
- **Limit execution to only the LXC container’s IP?**  
- **Log all actions to a file for auditing?**  
- **Automatically restart the container if it crashes?**  

Let me know how strict you want it!

That’s a great setup! You’ll have **Open-WebUI** running inside Docker, with **Llama 3.1 8B** as the default model, but you want an easy way to switch between:  

✅ **Llama 3.1 8B** (default)  
✅ **Qwen 2.5 7B**  
✅ **Hunyuan3D-2**  
✅ **Stable Diffusion 3.5 Medium**  

---

## **How to Implement Model Switching?**  
Since you're using **Docker**, the best way to switch models is via **environment variables** or a **volume-mounted config file**.  

Here are **two options**:  
1. **Switch via environment variable (fast & easy)**  
2. **Switch via a WebUI dropdown (user-friendly but needs customization)**  

---

## **Option 1: Switch Models via Environment Variables**  
We modify `docker-compose.yml` so that you can **easily switch models** by restarting the container with a different model name.

### **1. Modify `docker-compose.yml`**
```yaml
version: "3.8"

services:
  open-webui:
    image: ghcr.io/open-webui/open-webui:latest
    container_name: open-webui
    ports:
      - "3000:3000"
    environment:
      - MODEL_NAME=${MODEL_NAME:-Llama-3.1-8B} # Default model
    volumes:
      - ./models:/app/models
    restart: unless-stopped
```

### **2. Define Models in `.env`**
Create a file **`.env`** in the same directory as `docker-compose.yml`:

```
MODEL_NAME=Llama-3.1-8B
```

---

### **3. Change Models on the Fly**
To switch models, modify the `.env` file:  

```bash
echo "MODEL_NAME=Qwen-2.5-7B" > .env
docker-compose down && docker-compose up -d
```

Or, manually set it for a single session:  
```bash
MODEL_NAME=Hunyuan3D-2 docker-compose up -d
```

✅ This method is **simple** and doesn’t require modifying Open-WebUI.  
✅ Changes apply after a **restart**.  

---

## **Option 2: Switch Models via WebUI**
If you want a **dropdown in Open-WebUI** to select models, you need to **modify Open-WebUI’s config**.

### **1. Expose a Config File**
Instead of hardcoding the model in `docker-compose.yml`, mount a **config file**:

Modify **`docker-compose.yml`**:
```yaml
version: "3.8"

services:
  open-webui:
    image: ghcr.io/open-webui/open-webui:latest
    container_name: open-webui
    ports:
      - "3000:3000"
    volumes:
      - ./models:/app/models
      - ./config.json:/app/config.json # Mount config file
    restart: unless-stopped
```

---

### **2. Create `config.json`**
```json
{
  "default_model": "Llama-3.1-8B",
  "available_models": [
    "Llama-3.1-8B",
    "Qwen-2.5-7B",
    "Hunyuan3D-2",
    "Stable-Diffusion-3.5-Medium"
  ]
}
```

---

### **3. Modify Open-WebUI to Read `config.json`**
If Open-WebUI doesn’t support dynamic model selection, you may need to modify its source to read `config.json` and display available models.

---

## **Which Option is Best?**
| Method | Pros | Cons |
|--------|------|------|
| **Env Variable (`MODEL_NAME`)** | Simple, fast, works with any LLM server | Requires container restart |
| **WebUI Dropdown** | User-friendly, no restarts needed | Needs modifying Open-WebUI |

**Recommended:** If you want something quick and secure, use **Option 1 (env variables)**. If you need a user-friendly UI, **Option 2** is better.

Would you like help customizing Open-WebUI for model selection?


Yes! With **Option 2 (WebUI-based switching)**, we can make Open-WebUI **stop the current model and load a new one** dynamically without restarting the entire container.  

---

### **How It Will Work**
1. **A dropdown menu in Open-WebUI** allows selecting a model.  
2. **The backend reads `config.json`**, which lists available models.  
3. **When a model is switched**:  
   - The **current model stops**.  
   - The **new model loads** dynamically.  

---

## **Steps to Implement Dynamic Model Switching**

### **1. Modify `docker-compose.yml`**  
We mount a `config.json` file that stores model settings.  

```yaml
version: "3.8"

services:
  open-webui:
    image: ghcr.io/open-webui/open-webui:latest
    container_name: open-webui
    ports:
      - "3000:3000"
    volumes:
      - ./models:/app/models
      - ./config.json:/app/config.json # Mount config file
    restart: unless-stopped
```

---

### **2. Create `config.json` for Model Switching**  
This file defines available models and the currently active model.  

```json
{
  "default_model": "Llama-3.1-8B",
  "current_model": "Llama-3.1-8B",
  "available_models": [
    "Llama-3.1-8B",
    "Qwen-2.5-7B",
    "Hunyuan3D-2",
    "Stable-Diffusion-3.5-Medium"
  ]
}
```

---

### **3. Modify Open-WebUI Backend**
Since Open-WebUI runs models via a backend process (like `ollama` or `vllm`), we need to add a function that:  
- Reads `config.json`.  
- Stops the current model.  
- Loads the new model.  

#### **Modify `app.py` (or equivalent backend file in Open-WebUI)**
```python
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
```

---

### **4. Add a WebUI Dropdown for Model Selection**
Modify the frontend code (`frontend/src/components/Settings.js` or similar).  

#### **Example Dropdown UI**
```jsx
import { useState, useEffect } from "react";

const ModelSwitcher = () => {
    const [models, setModels] = useState([]);
    const [currentModel, setCurrentModel] = useState("");

    useEffect(() => {
        fetch("/config.json")
            .then(response => response.json())
            .then(data => {
                setModels(data.available_models);
                setCurrentModel(data.current_model);
            });
    }, []);

    const switchModel = (newModel) => {
        fetch(`/api/switch_model?model=${newModel}`, { method: "POST" })
            .then(() => setCurrentModel(newModel));
    };

    return (
        <div>
            <h3>Current Model: {currentModel}</h3>
            <select onChange={(e) => switchModel(e.target.value)} value={currentModel}>
                {models.map(model => (
                    <option key={model} value={model}>{model}</option>
                ))}
            </select>
        </div>
    );
};

export default ModelSwitcher;
```

---

### **5. Add an API Endpoint for Switching Models**
Modify **backend routes** (e.g., `routes.py` in Open-WebUI).  

```python
from flask import Flask, request, jsonify
from app import switch_model

app = Flask(__name__)

@app.route('/api/switch_model', methods=['POST'])
def api_switch_model():
    new_model = request.args.get('model')
    response = switch_model(new_model)
    return jsonify({"message": response})
```

---

### **6. Test Model Switching**
1. **Start Open-WebUI**  
   ```bash
   docker-compose up -d
   ```
2. **Go to WebUI** (`http://your-server-ip:3000`).  
3. **Select a model from the dropdown** → Open-WebUI will **stop the current model and load the new one dynamically**.

---

### **Final Security Enhancements**
✅ **Restrict model switching to specific users** (add authentication to `/api/switch_model`).  
✅ **Log all model switches** to a file (`switch_log.txt`).  
✅ **Add a "Restart Model" button** in case the switch fails.  

---

### **Next Steps**
Would you like me to help integrate this into Open-WebUI’s actual codebase? Or do you need assistance customizing the model startup commands?


Got it! You want to ensure that when switching models:  

✅ The **current model fully stops** (including unloading VRAM).  
✅ The **new model loads cleanly** with no memory leaks.  
✅ The process is **fully automated** within Open-WebUI.  

---

## **How to Fully Stop and Unload the Model?**  
Since VRAM is managed by the model-serving backend (e.g., `ollama`, `vllm`, `text-generation-webui`, or `comfyUI` for Stable Diffusion), we need to **properly terminate the existing model** before starting a new one.  

### **Steps to Achieve This**
1. **Identify and kill the running model process.**  
2. **Ensure VRAM is fully cleared.**  
3. **Start the new model cleanly.**  

---

## **1. Modify the Backend Model Switching Script**
Modify the backend script (`switch_model.py`) to properly stop and unload models.

### **New `switch_model.py`**
```python
import json
import subprocess
import time
import os

CONFIG_PATH = "/app/config.json"

def get_current_model():
    """Read current model from config file"""
    with open(CONFIG_PATH, "r") as f:
        config = json.load(f)
    return config["current_model"]

def stop_current_model():
    """Kill the current model and unload VRAM"""
    current_model = get_current_model()

    if not current_model:
        return "No model is currently running."

    # Kill process running the current model (modify for your backend)
    subprocess.run(["pkill", "-f", current_model], check=False)

    # Wait to ensure process stops
    time.sleep(3)

    # Free VRAM (only for Linux with NVIDIA GPUs)
    if os.path.exists("/usr/bin/nvidia-smi"):
        subprocess.run(["nvidia-smi", "--gpu-reset"], check=False)

    return f"Stopped {current_model} and cleared VRAM."

def switch_model(new_model):
    """Stop current model and start a new one"""
    with open(CONFIG_PATH, "r") as f:
        config = json.load(f)

    if new_model not in config["available_models"]:
        return "Error: Model not found"

    # Stop and unload VRAM
    stop_current_model()

    # Start new model (modify based on your LLM backend)
    subprocess.Popen(["ollama", "run", new_model], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    # Update config file
    config["current_model"] = new_model
    with open(CONFIG_PATH, "w") as f:
        json.dump(config, f)

    return f"Switched to {new_model}"
```

---

## **2. Modify WebUI Backend to Use This**
Modify `app.py` (or equivalent) to add an API endpoint for model switching.

```python
from flask import Flask, request, jsonify
from switch_model import switch_model

app = Flask(__name__)

@app.route('/api/switch_model', methods=['POST'])
def api_switch_model():
    new_model = request.args.get('model')
    response = switch_model(new_model)
    return jsonify({"message": response})
```

---

## **3. Modify the WebUI Dropdown for User Selection**
Modify **frontend code** (`Settings.js` or equivalent).

```jsx
import { useState, useEffect } from "react";

const ModelSwitcher = () => {
    const [models, setModels] = useState([]);
    const [currentModel, setCurrentModel] = useState("");

    useEffect(() => {
        fetch("/config.json")
            .then(response => response.json())
            .then(data => {
                setModels(data.available_models);
                setCurrentModel(data.current_model);
            });
    }, []);

    const switchModel = (newModel) => {
        fetch(`/api/switch_model?model=${newModel}`, { method: "POST" })
            .then(response => response.json())
            .then(data => {
                alert(data.message);
                setCurrentModel(newModel);
            });
    };

    return (
        <div>
            <h3>Current Model: {currentModel}</h3>
            <select onChange={(e) => switchModel(e.target.value)} value={currentModel}>
                {models.map(model => (
                    <option key={model} value={model}>{model}</option>
                ))}
            </select>
        </div>
    );
};

export default ModelSwitcher;
```

---

## **4. Test the Setup**
1. **Start Open-WebUI**  
   ```bash
   docker-compose up -d
   ```

2. **Visit WebUI (`http://your-server-ip:3000`)**  
   - Select a model from the dropdown.  
   - Open-WebUI will **stop the current model, clear VRAM, and load the new one**.

3. **Check VRAM before and after switching**
   ```bash
   nvidia-smi
   ```

---

## **Final Enhancements**
✅ **Ensure full VRAM release** using `nvidia-smi --gpu-reset`.  
✅ **Log all model switches** (`switch_log.txt`).  
✅ **Add a "Restart Model" button** if a switch fails.  

Would you like additional debugging tools or logs to verify model unloading?


# **Step-by-Step Guide: Secure Open-WebUI with Model Switching**  

This guide will walk you through setting up **Open-WebUI** inside Docker, ensuring **secure access**, and enabling **dynamic model switching** between:  
✅ **Llama 3.1 8B** *(default)*  
✅ **Qwen 2.5 7B**  
✅ **Hunyuan3D-2**  
✅ **Stable Diffusion 3.5 Medium**  

**The key features of this setup:**  
✔ **Secure Docker access** (user can only start/stop the container)  
✔ **Dynamically switch models** via a WebUI dropdown  
✔ **Properly stop models and unload VRAM** before switching  

---

## **1. Secure the Windows Environment**  
Since Open-WebUI runs inside Docker, we first ensure **limited access** to the Docker container.

### **Step 1.1: Create a Limited User**
1. Open **PowerShell as Administrator** and create a restricted user:  
   ```powershell
   net user dockeruser StrongPassword123! /add
   ```
2. Add the user to the **docker-users** group:  
   ```powershell
   Add-LocalGroupMember -Group "docker-users" -Member "dockeruser"
   ```
3. **Restrict Docker access** so `dockeruser` **can’t modify other containers**:  
   ```powershell
   icacls "C:\Program Files\Docker\Docker" /deny dockeruser:RX
   icacls "C:\Program Files\Docker\Docker\resources" /deny dockeruser:RX
   ```

---

## **2. Set Up Open-WebUI in Docker**
We will deploy Open-WebUI with a model-switching configuration.

### **Step 2.1: Install Docker & Docker Compose**
1. **Download and install Docker Desktop**: [Download](https://www.docker.com/products/docker-desktop/)  
2. **Verify Docker installation:**  
   ```powershell
   docker --version
   docker-compose --version
   ```

---

### **Step 2.2: Create `docker-compose.yml`**
Create a working directory:  
```powershell
mkdir C:\open-webui
cd C:\open-webui
```
Create `docker-compose.yml`:  
```yaml
version: "3.8"

services:
  open-webui:
    image: ghcr.io/open-webui/open-webui:latest
    container_name: open-webui
    ports:
      - "3000:3000"
    volumes:
      - ./models:/app/models
      - ./config.json:/app/config.json  # Mount config file for model switching
    restart: unless-stopped
```

---

### **Step 2.3: Create `config.json` for Model Switching**
Create a `config.json` file in `C:\open-webui`:  
```json
{
  "default_model": "Llama-3.1-8B",
  "current_model": "Llama-3.1-8B",
  "available_models": [
    "Llama-3.1-8B",
    "Qwen-2.5-7B",
    "Hunyuan3D-2",
    "Stable-Diffusion-3.5-Medium"
  ]
}
```

---

## **3. Implement Model Switching Backend**
We now add a Python script to **stop the current model, clear VRAM, and start a new one**.

### **Step 3.1: Create `switch_model.py`**
Create `C:\open-webui\switch_model.py`:  
```python
import json
import subprocess
import time
import os

CONFIG_PATH = "/app/config.json"

def get_current_model():
    """Read current model from config file"""
    with open(CONFIG_PATH, "r") as f:
        config = json.load(f)
    return config["current_model"]

def stop_current_model():
    """Kill the current model and unload VRAM"""
    current_model = get_current_model()

    if not current_model:
        return "No model is currently running."

    # Kill process running the current model
    subprocess.run(["pkill", "-f", current_model], check=False)

    # Wait to ensure process stops
    time.sleep(3)

    # Free VRAM (only for Linux with NVIDIA GPUs)
    if os.path.exists("/usr/bin/nvidia-smi"):
        subprocess.run(["nvidia-smi", "--gpu-reset"], check=False)

    return f"Stopped {current_model} and cleared VRAM."

def switch_model(new_model):
    """Stop current model and start a new one"""
    with open(CONFIG_PATH, "r") as f:
        config = json.load(f)

    if new_model not in config["available_models"]:
        return "Error: Model not found"

    # Stop and unload VRAM
    stop_current_model()

    # Start new model
    subprocess.Popen(["ollama", "run", new_model], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    # Update config file
    config["current_model"] = new_model
    with open(CONFIG_PATH, "w") as f:
        json.dump(config, f)

    return f"Switched to {new_model}"
```

---

### **Step 3.2: Add API Endpoint to WebUI Backend**
Modify `app.py` (or equivalent) in Open-WebUI:  
```python
from flask import Flask, request, jsonify
from switch_model import switch_model

app = Flask(__name__)

@app.route('/api/switch_model', methods=['POST'])
def api_switch_model():
    new_model = request.args.get('model')
    response = switch_model(new_model)
    return jsonify({"message": response})
```

---

## **4. Add WebUI Dropdown for Model Switching**
Modify `frontend/src/components/Settings.js`:

```jsx
import { useState, useEffect } from "react";

const ModelSwitcher = () => {
    const [models, setModels] = useState([]);
    const [currentModel, setCurrentModel] = useState("");

    useEffect(() => {
        fetch("/config.json")
            .then(response => response.json())
            .then(data => {
                setModels(data.available_models);
                setCurrentModel(data.current_model);
            });
    }, []);

    const switchModel = (newModel) => {
        fetch(`/api/switch_model?model=${newModel}`, { method: "POST" })
            .then(response => response.json())
            .then(data => {
                alert(data.message);
                setCurrentModel(newModel);
            });
    };

    return (
        <div>
            <h3>Current Model: {currentModel}</h3>
            <select onChange={(e) => switchModel(e.target.value)} value={currentModel}>
                {models.map(model => (
                    <option key={model} value={model}>{model}</option>
                ))}
            </select>
        </div>
    );
};

export default ModelSwitcher;
```

---

## **5. Run and Test**
1. **Start Open-WebUI**  
   ```powershell
   docker-compose up -d
   ```
2. **Visit WebUI (`http://your-server-ip:3000`)**  
3. **Switch Models** using the dropdown menu.  

---

## **6. Verify VRAM Unloading**
To check VRAM before and after model switching:  
```bash
nvidia-smi
```
If VRAM is not fully cleared, manually run:  
```bash
nvidia-smi --gpu-reset
```

---

## **Final Enhancements**
✅ **Restrict API access** (add authentication to `/api/switch_model`).  
✅ **Log model switches** (`switch_log.txt`).  
✅ **Add a "Restart Model" button** if switching fails.  

---

## **Done! 🎉**
You now have a **secure Open-WebUI** with **one-click model switching** that **properly clears VRAM**. Let me know if you need additional features! 🚀



