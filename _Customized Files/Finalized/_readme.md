Steps that goes one after another:

## **Step 1: Gather facts**
- think about variable files where we could gather the facts upfront and read them later from there?   

## **Step 2: Set Up SSH on Windows, create a new user, generate SSH keys and copy them**  

## **Step 3: Set Up SSH on Windows**  

## **Step 4: Run the Script from LXC**  





Unresolved things:

## **Security Considerations**
- **Use SSH keys instead of passwords.**  
- **Restrict SSH access** to only your LXC container's IP.  
- **Disable password authentication** in SSH by editing `C:\ProgramData\ssh\sshd_config` and setting:  
PasswordAuthentication no

### **Final Security Enhancements**
- Disable password SSH login (`PasswordAuthentication no` in `sshd_config`).  
- Restrict the user to LXC’s IP (`Match User dockeruser` in `sshd_config`).  
- Remove unneeded permissions (`icacls C:\scripts\start_docker.ps1 /inheritance:r`).  




