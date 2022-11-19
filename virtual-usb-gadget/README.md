Refs:

	https://qemu-project.gitlab.io/qemu/system/devices/usb.html
	https://www.linux-kvm.org/page/USB
	http://www.linux-usb.org/gadget/file_storage.html
	https://unix.stackexchange.com/questions/338026/centos-how-to-emulate-a-usb-flashdrive
	https://github.com/xairy/raw-gadget
	
	Load module with two instances: modprobe dummy_hcd num=2
	https://www.spinics.net/lists/linux-usb/msg76388.html

Documents:

	https://www.kernel.org/doc/html/latest/usb/raw-gadget.html
	https://www.kernel.org/doc/html/latest/usb/gadget_configfs.html
	https://www.kernel.org/doc/html/latest/usb/mass-storage.html

Virtual USB device that like a physical usb device

Require:

	linux headers instaled, git.

	For example on proxmox

	1. Add proxmox repos to /etc/apt/sources.list:
	https://pve.proxmox.com/wiki/Package_Repositories

        # PVE pve-no-subscription repository provided by proxmox.com,
        # NOT recommended for production use
        deb http://download.proxmox.com/debian/pve bullseye pve-no-subscription


	2. Update and install eve headers:
        apt update && apt install pve-headers-$(uname -r)


	3. Install git and clone project:
        apt install git
        git clone https://github.com/xairy/raw-gadget
        cd raw-gadget/dummy_hcd
        make
        

Create virtual USB image file (128M, change to what you want):

        dd bs=1024 count=128 if=/dev/zero of=/tmp/backing_file
        or
		dd bs=1M count=64 if=/dev/zero of=/root/data/backing_file
		or using qemu-img

Load virtual USB with g_mass_storage:

		cd raw-gadget/dummy_hcd
		./insmod.sh
        modprobe g_mass_storage removable=1 file=/root/usbstorage2.img idVendor0x0951= idProduct=0x1667 iManufacturer=Kingston iProduct="DataTraveler 3.0" iSerialNumber=E0D55EA573FCF3A0F82B0466 iInterface=1 bInterval=255

Note:

	this way, I can only create one virtual usb, or I don’t know how to setup multiple g_mass_storage!! After restart server, must to load modules again.
	And sometime got error: \\?\PhysicalDrive when create boot usb


Another way can make multiple virtual USB (no error \\?\PhysicalDrive): 

https://www.spinics.net/lists/linux-usb/msg90757.html

        modprobe -v udc_core
        isnmod ./raw-gadget/dummy_hcd/dummy_hcd.ko num=3 # <- load 3 instance of dummy_hcd
        modprobe libcomposite
        mount -t configfs none /sys/kernel/config
        cd /sys/kernel/config/usb_gadget
        mkdir g1
        cd g1
        ## configure them with attributes if needed
        mkdir configs/c.1
        ## create the function (name must match a usb_f_<name> module such as 'acm')
        mkdir functions/mass_storage.0
        ## associate with partitions, create lun.1 and add more if you want multiple luns
        ## create backing store(s) first with command:
        ##dd bs=1M count=16 if=/dev/zero of=/root/usb1.img
        echo /root/usb1.img > functions/mass_storage.0/lun.0/file
        mkdir strings/0x409
        mkdir configs/c.1/strings/0x409
        echo 0x0951 > idVendor
        echo 0x1667 > idProduct
        echo E0D55EA573FCF3A0F82B0466 > strings/0x409/serialnumber
        echo Kingston > strings/0x409/manufacturer
        echo "DataTraveler 3.0" > strings/0x409/product
        echo "removable=1 iInterface=1 bInterval=255" > configs/c.1/strings/0x409/configuration
        echo 120 > configs/c.1/MaxPower
        ## associate function with config
        ln -s functions/mass_storage.0 configs/c.1
        ## enable gadget by binding it to a UDC from /sys/class/udc
        echo dummy_udc.0 > UDC
        ## turn off: echo "" > UDC
        ##

		Check it loaded?:
        	lsusb
        	Bus 004 Device 002: ID 0951:0104 Kingston Technology VirtualBlockDevice


Another way to create virtual usb and mount directly in proxmox vm
	vm config file - /etc/pve/qemu-server/100.conf
    
    works but 0M in create boot application

	args: -device piix3-usb-uhci,addr=0x18 -drive id=my_usb_disk,file=/root/virtual_usb.img,if=none,format=raw -device usb-storage,id=my_usb_disk,drive=my_usb_disk
		
	args: -device nec-usb-xhci,id=xhci -drive if=none,id=stick,format=raw,file=/root/virtual_usb.img -device usb-storage,bus=xhci.0,drive=stick
		
	args: -device piix3-usb-uhci -drive if=none,id=stick,format=raw,file=/root/virtual_usb.img -device usb-storage,drive=stick

	args: -device nec-usb-xhci,id=xhci -drive id=stick,if=none,format=raw,file=/root/ss/root/virtual_usb.img -device usb-storage,drive=stick -device usb-host,vendorid=0x0951,productid=0x1670






REAL USB INFORMATION


	Bus 002 Device 003: ID 0951:1666 Kingston Technology DataTraveler 100 G3/G4/SE9 G2/50
	Device Descriptor:
	bLength                18
	bDescriptorType         1
	bcdUSB               2.10
	bDeviceClass            0 
	bDeviceSubClass         0 
	bDeviceProtocol         0 
	bMaxPacketSize0        64
	idVendor           0x0951 Kingston Technology
	idProduct          0x1666 DataTraveler 100 G3/G4/SE9 G2/50
	bcdDevice            0.01
	iManufacturer           1 Kingston
	iProduct                2 DataTraveler 3.0
	iSerial                 3 E0D55EA573FCF3A0F82B0464
	bNumConfigurations      1
	Configuration Descriptor:
		bLength                 9
		bDescriptorType         2
		wTotalLength       0x0020
		bNumInterfaces          1
		bConfigurationValue     1
		iConfiguration          0 
		bmAttributes         0x80
		(Bus Powered)
		MaxPower              300mA
		Interface Descriptor:
		bLength                 9
		bDescriptorType         4
		bInterfaceNumber        0
		bAlternateSetting       0
		bNumEndpoints           2
		bInterfaceClass         8 Mass Storage
		bInterfaceSubClass      6 SCSI
		bInterfaceProtocol     80 Bulk-Only
		iInterface              0 
		Endpoint Descriptor:
			bLength                 7
			bDescriptorType         5
			bEndpointAddress     0x81  EP 1 IN
			bmAttributes            2
			Transfer Type            Bulk
			Synch Type               None
			Usage Type               Data
			wMaxPacketSize     0x0200  1x 512 bytes
			bInterval             255
		Endpoint Descriptor:
			bLength                 7
			bDescriptorType         5
			bEndpointAddress     0x02  EP 2 OUT
			bmAttributes            2
			Transfer Type            Bulk
			Synch Type               None
			Usage Type               Data
			wMaxPacketSize     0x0200  1x 512 bytes
			bInterval             255
	Binary Object Store Descriptor:
	bLength                 5
	bDescriptorType        15
	wTotalLength       0x0016
	bNumDeviceCaps          2
	USB 2.0 Extension Device Capability:
		bLength                 7
		bDescriptorType        16
		bDevCapabilityType      2
		bmAttributes   0x00000006
		BESL Link Power Management (LPM) Supported
	SuperSpeed USB Device Capability:
		bLength                10
		bDescriptorType        16
		bDevCapabilityType      3
		bmAttributes         0x00
		wSpeedsSupported   0x000e
		Device can operate at Full Speed (12Mbps)
		Device can operate at High Speed (480Mbps)
		Device can operate at SuperSpeed (5Gbps)
		bFunctionalitySupport   2
		Lowest fully-functional device speed is High Speed (480Mbps)
		bU1DevExitLat          10 micro seconds
		bU2DevExitLat        2047 micro seconds
	can't get debug descriptor: Resource temporarily unavailable
	Device Status:     0x0000
	(Bus Powered)
