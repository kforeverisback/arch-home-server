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
- Modify k3d-resolv.conf accordingly, using which k3d will add DNS nameserver entries to the cluster

