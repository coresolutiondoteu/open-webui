#Generate a new SSH key:
ssh-keygen -t rsa -b 4096 -f ~/.ssh/windows_ssh_key

#Copy the public key to the Windows machine:
ssh-copy-id -i ~/.ssh/windows_ssh_key.pub dockeruser@windows-ip

#Test the connection:
ssh -i ~/.ssh/windows_ssh_key dockeruser@windows-ip "hostname"
ssh -i ~/.ssh/windows_ssh_key dockeruser@windows-ip "docker ps"