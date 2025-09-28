# Proof of Concept: FHS Debian Netboot System
This is a Debian Live System for web surfing, office work and media playback.  It is intended as a proof of concept (PoC) for utilizing a **Netboot/PXE** system in an educational environment (e.g., a school).

## Building the system image
This system uses [Debian Linux](https://www.debian.org/) as the operating system and the [Debian Live Project's](https://www.debian.org/devel/debian-live/) build system. We extend our gratitude to the Debian Community.

### Requirements
1. A x86_64 Computer running Debian as the *build machine*.
2. The package: live-build
3. The *debian* directory contained within this repository.

### Build Process
Navigate into the `debian` directory and run:

```
sudo lb clean
sudo lb config
sudo lb build
```

The netbooting binaries will be located in the directory `debian/binary/live/`.

## Setting up a NetBoot Server
This section details how to configure your build machine as simple netboot server. You must set the appropriate options on your networks *DHCP server* (usually the network's router). Please consult your routers manual or contact your routers manufacturer. If this is not your network, please contact the network administrators.

### 0. DHCP Configuration
On your DHCP-Server:
1. Ensure your build machine has a **fixed IP addres**s.
2. Set *dhcp next server* to your build machine's ip address.
3. Set *dhcp option 66* to your build machine's ip address.
4. Set *dhcp option 67* to `/var/netboot/syslinux.efi`.

**Note:** You must also replace the placeholder IP address `192.168.178.10` with your build machine’s actual IP address in the file `debian/pxelinux.cfg/default`.

### 1. Packages
Required packages: nfs-kernel-server syslinux-common syslinux-efi tftpd-hpa

#### 1.1 Create the Netboot Directory
Create the necessary directory for the netboot files:
```
sudo mkdir -p /var/netboot
```

#### 1.2 Copy Bootloader Files
This example uses [Syslinux](https://syslinux.org/) as bootloader, consists of multiple files. Copy the required files to the netboot directory:

```
sudo cp /lib/syslinux/modules/efi64/* /var/netboot
sudo cp /lib/SYSLINUX.EFI/efi64/* /var/netboot
```

#### 1.3 TFTP Server Configuration
The the target system's UEFI firmware will download the initial boot files via the TFTP protocol. Therefore, we need to serve the netboot files using the TFTP service.

Change your TFTP configuration file content (`/etc/default/tftpd-hpa`) to the following:
```
# /etc/default/tftpd-hpa

TFTP_USERNAME="tftp"
TFTP_DIRECTORY="/var/netboot"
TFTP_ADDRESS=":69"
TFTP_OPTIONS="--permissive -v"
```

Restart the TFTP server to apply the new configuration:
```
sudo systemctl restart tftp-hpa.service
```

*For Testing:* You can connect and download files from your tftp server via the command tftp (package: tftp-hpa).

#### 1.4 NFS Server Configuration
The Linux Kernel will use the NFS protocol to access the root filesystem, which is stored in `/var/netboot/live/filesystem.squashfs`.

Add the following line to the NFS exports file (/etc/exports):
```
/var/netboot 192.168.0.0/16(ro,insecure,no_subtree_check)
```

**Important:** The specified IP range `192.168.0.0/16` describes which machines can access the NFS server. Please change this to match your LANIP range.

Restart the NFS server to apply the new configuration:
```
sudo systemctl restart nfs-server.service
```

*Note:* My system reported `nfsdctl: lockd configuration failure` in `systemctl status nfs-server.service`, but the NFS server worked correctly regardless.

#### 1.5 Set Server IP in pxelinux config
In line 10 of `debian/pxelinux.cfg/default`, replace the placeholder IP address `192.168.178.10` with your netboot server's (build machine's) IP address.

#### 1.6 Copy image files
Copy the required files from the *debian* directory to the */var/netboot/* directory. Run the script `copy-to-netboot.sh` from inside the *debian* directory:
```
sudo ./copy-to-netboot.sh
```


#### 1.7 Set File Permissions
Most files in `/var/netboot` must be executable. Run this command to set the permissions recursively:
```
sudo chmod -R +x /var/netboot/*
```


## NetBooting the Client Machine
Client Machine Requirements:
* **x86_64** Processor
* at least **8 GB** of RAM
* **Ethernet** (minmum 1000 Mbit/s recommended) connected to the same network as the netboot server
* **UEFI** with **PXE-Boot** support

### UEFI Setup
Access the client machines's UEFI setup and ensure the following:
1. PXE-boot is enabled.
2. PXE-boot is set as the first entry in the boot order list.

### Start-Up
Start your machine, it should automaticly boot via network. 

**Important:** Keep the network cable plugged in. If you need to unplug the network cable after the initial boot phase, you must add the option *toram* to line 10 of the pxelinux configuration file.

