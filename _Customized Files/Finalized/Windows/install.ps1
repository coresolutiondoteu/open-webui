#Add OpenSSH Server
Add-WindowsFeature -Name OpenSSH-Server

#Start and enable the SSH service:  
Start-Service sshd
Set-Service -Name sshd -StartupType Automatic

#Allow the SSH server through the Windows Firewall:
#NOTE: This is a very permissive rule. Please tighten it as necessary.
New-NetFirewallRule -Name sshd -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22

#Create an SSH User** (if needed)  
net user dockeruser StrongPassword123! /add

#Add the dockeruser to docker-users group for non-admin access
Add-LocalGroupMember -Group "docker-users" -Member "dockeruser"

#Reboot the machine to apply the changes
shutdown.exe /r /t 0




