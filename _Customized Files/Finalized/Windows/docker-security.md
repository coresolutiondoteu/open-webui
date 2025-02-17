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