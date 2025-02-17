## **3. Test Docker Access Without Admin Rights**  
# Log in as `dockeruser` and test if it can run Docker commands.  

# 1. Switch to `dockeruser`:
#   ```powershell
runas /user:dockeruser cmd
#   ```
# 2. Try running Docker:
#   ```powershell
docker ps
#   ```
#   If you see running containers (or an empty list), it’s working!


## **4. Allow the User to Run the Script via SSH**  
# Now, make sure `dockeruser` can SSH into the Windows machine.  

# 1. **Enable SSH for `dockeruser`**  
#   Open `C:\ProgramData\ssh\sshd_config` and allow the user:
#   ```
AllowUsers dockeruser
#   ```
# 2. Restart the SSH service:
#   ```powershell
Restart-Service sshd
#   ```

# 3. **Copy your SSH key** to the user’s profile:  
#   On your **LXC container**, run:  
#   ```bash
ssh-copy-id -i ~/.ssh/windows_ssh_key.pub dockeruser@windows-ip
#   ```

#34. **Test SSH access**:  
#  ```bash
ssh -i ~/.ssh/windows_ssh_key dockeruser@windows-ip "docker ps"
#   ```