# ssh -i ~/.ssh/windows_ssh_key dockeradmin@windows-ip "powershell -ExecutionPolicy Bypass -File C:\scripts\start_docker.ps1"

# Starting the service on the remote Windows host:
ssh -i ~/.ssh/windows_ssh_key dockeruser@windows-ip "powershell -ExecutionPolicy Bypass -File C:\scripts\start_docker.ps1"
