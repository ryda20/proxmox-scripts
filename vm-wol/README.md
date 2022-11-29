
1. Situation:
   
   i want to turn on vm in proxmox node by sending broadcast signal through the network.
   My vm run in separated network with proxmox server.
   The broadcast signal can not go out to main proxmox network.

2. What is it?
   
   So, this scripts use to capture wol signal (send from a virtual machine), then, forward this signal to proxmox server by netcat

3. How is works?
   
   Have two parts: one in vm and one in proxmox server.
   1. Script in vm will run in while loop and waiting for broadcast signal, then, forward to the script running in proxmox server by nc
   2. Script in proxmox server will wait to receive broadcast signal from script running inside vm, then, get out the MAC address
   3. Base on mac address, using qm to find out vm id need to start and start it.
   
4. How to use?
   
   1. clone this repos to your local.
   2. Create a service in vm with command:
    	```sh
			./vm-wol-debian.sh install vm
		```
	3. Create a service in proxmox server with command:
    	```sh
			./vm-wol-debian.sh install
		```
	4. You can check status/start/stop/enable:
       	```sh
			systemctl status proxmox-vm-wol
			systemctl start proxmox-vm-wol
			systemctl stop proxmox-vm-wol
			systemctl enable proxmox-vm-wol
		```


Note: the install script will start and enable automatic
Note: the broadcast signal maybe need to set to: 255.255.255.255
