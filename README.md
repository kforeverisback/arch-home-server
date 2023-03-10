# Arch Home Server Install Guide

## Setting up Arch Linux
- Followed [this guide to setup arch-isio and partition disks to btrfs](https://github.com/Deebble/arch-btrfs-install-guide).

- After mounting, followed [this guide from generating fstab and setting up `systemd-boot`](https://nerdstuff.org/posts/2021/2021-001_arch_linux_btrfs_systemd-boot/).

- Make sure to follow [this guide to avoid boot fail on `mkinitcpio` not copying files to EFI partition.](https://wiki.archlinux.org/title/EFI_system_partition#Using_systemd). Use either `systemd` or `mkinitcpio` hooks

- [WIP] Afterwards installing necessary tools [following this guide](https://github.com/zilexa/Homeserver/blob/master/prep-server.sh) or [this script](./prep-server.sh)

- Create Parition for k3d-data and docker-data

## Deploying k3d cluster

Use make create to deploy the k3d cluster

The k3d cluster will create
- A docker network
- A registry at port localhost:5000
- A volume would be added to the single docker node
- 20 ports will be forwarded (31100-31120)

Notes:
- Make sure the mount paths(k3s-data) is properly set and initialized
  - Currently its using a SDCard partioned as BTRFS volm
<!-- - Modify k3d-resolv.conf accordingly, using which k3d will add DNS nameserver entries to the cluster -->
- Make sure to add the k3d-network to ufw firewall
```bash
# first backup after.rules
sudo cp -r /etc/ufw/after{,-b4-k3d-network}.rules
k3d_subnet=$(docker network inspect k3d-network | jq '.[].IPAM.Config[].Subnet' -r)
sed -i '/-A DOCKER-USER .* 172.16.*/p;s/172.16.*/'${k3d_subnet/\//\\\/}'/' /etc/ufw/after.rules
sudo systemctl restart ufw
```

### Basic Structure of Homebox

- Applications (e.g. Homebox) which doesn't require a HW, runs on Kubernetes
- Appliatsions which rquires HW (usb) that runs on Docker Compose/Docker

#### Kubernetes cluster brief

- Uses k3d to create a single node cluster
- Runs Traefik as Load Balancer
- Each program will use its own hostname matching
  - **Note**, hostname DNS is currently mananged by Home Gargoyle Router
  -  The application specific DNSs are wildcard, e.g. homebox.chromebox.lan translates to *.chromebox.lan
  - Added this line to `dnsmasq.conf`: `address=/chromebox.lan/10.110.210.248`
