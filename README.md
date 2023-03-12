# Arch Home Server Install Guide

## Setting up Arch Linux
- Followed [this guide to setup arch-isio and partition disks to btrfs](https://github.com/Deebble/arch-btrfs-install-guide).

- After mounting, followed [this guide from generating fstab and setting up `systemd-boot`](https://nerdstuff.org/posts/2021/2021-001_arch_linux_btrfs_systemd-boot/).

- Make sure to follow [this guide to avoid boot fail on `mkinitcpio` not copying files to EFI partition.](https://wiki.archlinux.org/title/EFI_system_partition#Using_systemd). Use either `systemd` or `mkinitcpio` hooks

- [WIP] Afterwards installing necessary tools [following this guide](https://github.com/zilexa/Homeserver/blob/master/prep-server.sh) or [this script](./prep-server.sh)

- Create Parition for k3d-data and docker-data

## Deploying k3d cluster

Follow [this doc](./k8s-deploy/k3d-cluster/README.md).

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
