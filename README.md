# Arch Home Server Install Guide

- Followed [this guide to setup arch-isio and partition disks to btrfs](https://github.com/Deebble/arch-btrfs-install-guide).

- After mounting, followed [this guide from generating fstab and setting up `systemd-boot`](https://nerdstuff.org/posts/2021/2021-001_arch_linux_btrfs_systemd-boot/).

- Make sure to follow [this guide to avoid boot fail on `mkinitcpio` not copying files to EFI partition.](https://wiki.archlinux.org/title/EFI_system_partition#Using_systemd). Use either `systemd` or `mkinitcpio` hooks

- [WIP] Afterwards installing necessary tools [following this guide](https://github.com/zilexa/Homeserver/blob/master/prep-server.sh) or [this script](./prep-server.sh)
