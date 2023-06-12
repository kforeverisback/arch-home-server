#!/bin/bash
# >>> DO NOT USE THIS FILE ON UBUNTU. USE /ARCHIVED/ INSTEAD. THIS FILE HAS BEEN ADJUSTED FOR MANJARO LINUX. <<<

RM=/bin/rm
[[ -z $SSH_PORT ]] && SSH_PORT=420
pause () { read -rsn1 > /dev/null; }

echo "   Symlink resolvd to systemd-resovled stub   "
echo "----------------------------------------------" 
sudo rm /etc/resolv.conf
sudo ln -s /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

echo "____________________________________________"
echo "           INSTALL YAY&tools                "
echo "                                            "
echo "____________________________________________"
sed -i '/\[options\]/a Color\
ILoveCandy' /etc/pacman.conf
echo y | sudo pacman -S --needed git base-devel
cd /tmp || exit
git clone https://aur.archlinux.org/yay-bin.git
cd yay-bin  || exit
makepkg -si
cd /tmp  || exit
$RM -r yay-bin

# Now install some terminal tools
mkdir -p ~/.local/bin/
yay -S fd bat exa procs starship bottom ranger sd dust tokei tealdeer git-delta git-extras powertop tailscale --noconfirm
cp zshrc-post ~/
echo 'source ~/zshrc-post' >> ~/.zshrc
# Install chtsh
curl -s https://cht.sh/:cht.sh | sudo tee /usr/local/bin/cht.sh > /dev/null && sudo chmod +x /usr/local/bin/cht.sh
ln -s /usr/local/bin/cht.sh ~/.local/bin

#python3 -m pip install --user pipx
# Install via pipx: yq, httpie, pyinfra

echo "____________________________________________"
echo "           INSTALL SERVER TOOLS             "
echo "                                            "
echo "____________________________________________"
echo "         Docker and Docker Compose          "
echo "--------------------------------------------"
pause
# Install Docker and Docker Compose
yay install -S docker docker-compose --noconfirm

# Create non-root user for docker, with privileges (not docker rootless)
sudo groupadd docker
sudo usermod -aG docker "$USER"

# Enable docker at boot
sudo systemctl enable docker.service
sudo systemctl enable containerd.service

echo "           K3d kubernetes cluster           "
echo "--------------------------------------------"
yay -S rancher-k3d-bin kubectl --noconfirm
# Install krew as well
# Following https://krew.sigs.k8s.io/docs/user-guide/setup/install/
(
  set -x; cd "$(mktemp -d)" &&
  OS="$(uname | tr '[:upper:]' '[:lower:]')" &&
  ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')" &&
  KREW="krew-${OS}_${ARCH}" &&
  curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/${KREW}.tar.gz" &&
  tar zxvf "${KREW}.tar.gz" &&
  ./"${KREW}" install krew
)


echo "            Wireguard VPN Tools             "
echo "--------------------------------------------"
# If you used the post-install script, this should already be installed
yay -S wireguard-tools --noconfirm

echo "       Install UFW, iptables-nft and ufw-docker           "
echo "--------------------------------------------"
yay -S iptables-nft --noconfirm
yay -S ufw ufw-extras ufw-docker --noconfirm
wget -qO- https://github.com/shinebayar-g/ufw-docker-automated/releases/download/v0.11.0/ufw-docker-automated_0.11.0_linux_amd64.tar.gz | tar xz -C /tmp
sudo mv /tmp/ufw-docker-automated /usr/local/bin/
# Install systemd service
echo "[Unit]
Description=Ufw docker automated
Documentation=https://github.com/shinebayar-g/ufw-docker-automated
After=network-online.target ufw.service containerd.service
Wants=network-online.target
Requires=ufw.service

[Service]
# To manage ufw rules, binary has to run as a root or sudo privileged user.
# User=ubuntu
# Provide /path/to/ufw-docker-automated
ExecStart=/usr/local/bin/ufw-docker-automated
Restart=always

[Install]
WantedBy=multi-user.target" | sudo tee -a /lib/systemd/system/ufw-docker-automated.service > /dev/null
sudo systemctl daemon-reload
sudo systemctl enable ufw-docker-automated --now
# Allow container and the private bridge network can visit each other normally
sudo ufw-docker install
sudo systemctl enable ufw --now
# Now enable certain ports in ufw
sudo ufw allow to any port $SSH_PORT

echo "                   BTRBK                    "
echo "--------------------------------------------"
echo "Swiss handknife-like tool to automate snapshots & backups of personal data"
# available in the Arch User Repository (AUR) thus installed via Pamac. Will be automatically updated just like official repository packages. 
yay -S btrbk --noconfirm

echo "        RUN-IF-TODAY & ENABLE CRON          "
echo "--------------------------------------------"
echo "simplify scheduling of weekly/monthly tasks"
sudo wget -O /usr/bin/run-if-today https://raw.githubusercontent.com/xr09/cron-last-sunday/master/run-if-today
sudo chmod +x /usr/bin/run-if-today
echo "enable cron service" 
systemctl enable --now cronie.service

echo "                   NOCACHE                  "
echo "--------------------------------------------"
echo "handy when moving lots of files at once in the background, without filling up cache and slowing down the system."
# available in the Arch User Repository (AUR) thus installed via Pamac. Will be automatically updated just like official repository packages. 
yay -S nocache --noconfirm

# echo "                    GRSYNC                  "
# echo "--------------------------------------------"
# echo "Friendly UI for rsync"
# sudo pamac install --no-confirm grsync

echo "                  LM_SENSORS                "
echo "--------------------------------------------"
echo "to be able to read out all sensors" 
yay -S lm_sensors --noconfirm
sudo sensors-detect --auto

echo "          S.M.A.R.T. monitoring             "
echo "--------------------------------------------"
echo "to be able to read SMART values of drives" 
yay -S smartmontools

echo "                 HD PARM                    "
echo "--------------------------------------------"
echo "to be able to configure drive parameters" 
yay -S hdparm --noconfirm

# echo "                 MERGERFS                  "
# echo "-------------------------------------------"
# echo "pool drives to make them appear as 1 without raid"
# # available in the Arch User Repository (AUR) thus installed via Pamac. Will be automatically updated just like official repository packages. 
# sudo pamac install --no-confirm mergerfs

echo "______________________________________________________"
echo "                     SYSTEM CONFIG                    "
echo "______________________________________________________"

echo "  Optimize power consumption  "
echo "------------------------------"
# Always run Powertop autotune at boot
# Powertop is a tool provided by Intel to enable various powersaving modes in userspace, kernel and hardware
sudo tee -a /etc/systemd/system/powertop.service << EOF
[Unit]
Description=Powertop tunings

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/bin/powertop --auto-tune

[Install]
WantedBy=multi-user.target
EOF
## Enable the service
sudo systemctl daemon-reload
sudo systemctl enable powertop.service
## Tune system now
sudo powertop --auto-tune
## Start the service
sudo systemctl start powertop.service


echo "    Auto-restart VPN server   "
echo "------------------------------" 
# Automatically restart Wireguard VPN server when the wireguard config file is modified (by VPN-Portal webUI)
# Monitor the wireguard config file for changes
sudo tee -a /etc/systemd/system/wgui.path << EOF
[Unit]
Description=Watch /etc/wireguard/wg0.conf for changes

[Path]
PathModified=/etc/wireguard/wg0.conf

[Install]
WantedBy=multi-user.target
EOF
# Restart wireguard service automatically
sudo tee -a /etc/systemd/system/wgui.service << EOF
[Unit]
Description=Restart WireGuard
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/bin/systemctl restart wg-quick@wg0.service

[Install]
RequiredBy=wgui.path
EOF
# Apply these services
systemctl enable --now wgui.{path,service}

# Setup SSH
## Disable Password Auth
sed -r 's/(^# P|^#P|^P)asswordAuthentication.*/PasswordAuthentication no/g' sshd_config
## Change port to 420
## TODO Make it to Arg
sed -r "s/^Port 22|^#.*Port 22/Port $SSH_PORT/g" sshd_config


echo "    EMAIL NOTIFICATIONS       "
echo "------------------------------"
# allow system to send email notifications - Configure smtp according to Arch wiki
sudo pamac install --no-confirm msmtp
sudo pamac install --no-confirm s-nail
# link sendmail to msmtp
sudo ln -s /usr/bin/msmtp /usr/bin/sendmail
sudo ln -s /usr/bin/msmtp /usr/sbin/sendmail
# set msmtp as mta
echo "set mta=/usr/bin/msmtp" | sudo tee -a /etc/mail.rc
echo ">>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<"
echo "                                                             "
echo "To receive important server notifications, please enter your main/default emailaddress that should receive notifications:"
echo "                                                             "
read -p 'Enter email address to receive server notifications:' DEFAULTEMAIL
sudo sh -c "echo default:$DEFAULTEMAIL >> /etc/aliases"
## Get config file
sudo tee -a /etc/msmtprc &>/dev/null << EOF
# Set default values for all following accounts.
defaults
auth           on
tls            on
#tls_trust_file /etc/ssl/certs/ca-certificates.crt
#logfile        $HOME/docker/HOST/logs/msmtp.log
aliases        /etc/aliases

# smtp provider
account        default
host           mail.smtp2go.com
port           587
from           FROMADDRESS
user           SMTPUSER
password       SMTPPASS
EOF
# set SMTP server
echo "  ADD SMTP CREDENTIALS FOR EMAIL NOTIFICATIONS  "
echo ">>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<"
echo "                                                            "
echo "Would you like to configure sending email now? You need to have an smtp provider account correctly configured with your domain" 
read -p "Have you done that and do you have your smtp credentials at hand? (y/n)" answer
case ${answer:0:1} in
    y|Y )
    read -p "Enter SMTP server address (or hit ENTER for default: mail.smtp2go.com):" SMTPSERVER
    SMTPSERVER="${SMTPSERVER:=mail.smtp2go.com}"
    read -p "Enter SMTP server port (or hit ENTER for default:587):" SMTPPORT
    SMTPPORT="${SMTPPORT:=587}"
    read -p 'Enter SMTP username: ' SMTPUSER
    read -p 'Enter password: ' SMTPPASS
    read -p 'Enter the from emailaddress that will be shown as sender, for example username@yourdomain.com: ' FROMADDRESS
    sudo sed -i -e "s#mail.smtp2go.com#$SMTPSERVER#g" /etc/msmtprc
    sudo sed -i -e "s#587#$SMTPPORT#g" /etc/msmtprc
    sudo sed -i -e "s#SMTPUSER#$SMTPUSER#g" /etc/msmtprc
    sudo sed -i -e "s#SMTPPASS#$SMTPPASS#g" /etc/msmtprc
    sudo sed -i -e "s#FROMADDRESS#$FROMADDRESS#g" /etc/msmtprc
    echo "Done, now sending you a test email...." 
    printf "Subject: Your Homeserver is almost ready\nHello there, I am almost ready. I can sent you emails now." | msmtp -a default $DEFAULTEMAIL
    echo "Email sent!" 
    echo "if an error appeared above, the email has not been sent and you made an error or did not configure your domain and smtp provider" 
    ;;
    * )
        echo "Not configuring SMTP. Please manually enter your SMTP provider details in file /etc/msmprc.." 
    ;;
esac


echo "  on-demand btrfs root mount  "
echo "-------------------------------"
# on-demand systemdrive mountpoint 
## The MANJARO GNOME POST INSTALL SCRIPT has created a mountpoint for systemdrive. If that script was not used, create the mountpoint now:
# Get device path of systemdrive, for example "/dev/nvme0n1p2" via #SYSTEMDRIVE=$(df / | grep / | cut -d" " -f1)
if sudo grep -Fq "/mnt/drives/system" /etc/fstab; then echo already added by post-install script; 
else 
# Add an ON-DEMAND mountpoint in FSTAB for the systemdrive, to easily do a manual mount when needed (via "sudo mount /mnt/drives/system")
sudo mkdir -p /mnt/drives/system
# Get the systemdrive UUID
fs_uuid=$(findmnt / -o UUID -n)
# Add mountpoint to FSTAB
sudo tee -a /etc/fstab &>/dev/null << EOF

# Allow easy manual mounting of btrfs root subvolume                         
UUID=${fs_uuid} /mnt/drives/system  btrfs   subvolid=5,defaults,noatime,noauto  0  0
EOF
fi
sudo mount -a

echo "        Docker subvolume       "
echo "-------------------------------"
# create subvolume for Docker persistent data
# Temporarily Mount filesystem root
sudo mount /mnt/drives/system
# create a root subvolume for docker
sudo btrfs subvolume create /mnt/drives/system/@docker
## unmount root filesystem
sudo umount /mnt/drives/system
# Create mountpoint, to be used by fstab
mkdir $HOME/docker
# Get system fs UUID, to be used for next command
fs_uuid=$(findmnt / -o UUID -n)
# Add @docker subvolume to fstab to mount on mountpoint at boot
sudo tee -a /etc/fstab &>/dev/null << EOF

# Mount @docker subvolume
UUID=${fs_uuid} $HOME/docker  btrfs   subvol=@docker,defaults,noatime,x-gvfs-hide,compress-force=zstd:1  0  0
EOF
sudo mount -a
sudo chown ${USER}:${USER} $HOME/docker
sudo chmod -R 755 $HOME/docker
#sudo setfacl -Rdm g:docker:rwx $HOME/docker

echo "Create the minimum folder structure for drives and datapool"
echo "--------------------------------------------"
sudo mkdir /mnt/drives/{data0,data1}
sudo mkdir /mnt/drives/backup1
sudo mkdir -p /mnt/pool/


echo "______________________________________________________________________"
echo "                                                                      " 
echo " GET THE homeserver guide DOCKER COMPOSE FILE and MAINTENANCE SCRIPTS "
echo "______________________________________________________________________"
cd $HOME/Downloads
echo "         compose yml and env file           "
echo "--------------------------------------------"
wget -O $HOME/docker/.env https://raw.githubusercontent.com/zilexa/Homeserver/master/docker/.env
wget -O $HOME/docker/docker-compose.yml https://raw.githubusercontent.com/zilexa/Homeserver/master/docker/docker-compose.yml

echo "               mediacleaner                 "
echo "--------------------------------------------"
mkdir -p $HOME/docker/HOST/mediacleaner
wget -O $HOME/docker/HOST/mediacleaner/media_cleaner.py https://raw.githubusercontent.com/terrelsa13/media_cleaner/master/media_cleaner.py
wget -O $HOME/docker/HOST/mediacleaner/media_cleaner_config_defaults.py https://raw.githubusercontent.com/terrelsa13/media_cleaner/master/media_cleaner_config_defaults.py
# make it executable
chmod +x $HOME/docker/HOST/mediacleaner/media_cleaner.py
# install required dependency
sudo pamac install --no-confirm python-dateutil

echo "      BTRBK config and mail script          "
echo "--------------------------------------------"
mkdir -p $HOME/docker/HOST/btrbk
wget -O $HOME/docker/HOST/btrbk/btrbk.conf https://raw.githubusercontent.com/zilexa/Homeserver/master/docker/HOST/btrbk/btrbk.conf
wget -O $HOME/docker/HOST/btrbk/btrbk-mail.sh https://raw.githubusercontent.com/zilexa/Homeserver/master/docker/HOST/btrbk/btrbk-mail.sh
sudo ln -s $HOME/docker/HOST/btrbk/btrbk.conf /etc/btrbk/btrbk.conf
# MANUALLY configure the $HOME/docker/HOST/btrbk/btrbk.conf to your needs

echo "                 archiver                   "
echo "--------------------------------------------"
mkdir -p $HOME/docker/HOST/archiver
wget -O $HOME/docker/HOST/archiver/archiver.sh https://raw.githubusercontent.com/zilexa/Homeserver/master/docker/HOST/archiver/archiver.sh
wget -O $HOME/docker/HOST/archiver/archiver_exclude.txt https://github.com/zilexa/Homeserver/blob/master/docker/HOST/archiver/archiver_exclude.txt

echo "Tools to auto-notify or auto-update docker images & containers"
echo "--------------------------------------------------------------"
# PULLIO - to auto-update
mkdir -p $HOME/docker/HOST/updater
sudo curl -fsSL "https://raw.githubusercontent.com/hotio/pullio/master/pullio.sh" -o $HOME/docker/HOST/updater/pullio
sudo chmod +x $HOME/docker/HOST/updater/pullio
sudo ln -s $HOME/docker/HOST/updater/pullio /usr/local/bin/pullio
# DIUN - to auto-notify

# Get config file
sudo mkdir -p $HOME/docker/HOST/updater/diun
sudo tee -a $HOME/docker/HOST/updater/diun/diun.yml &>/dev/null << EOF
notif:
  mail:
    host: 
    port: 587
    ssl: false
    insecureSkipVerify: true
    username: 
    password: 
    from: 
    to: 

providers:
  docker:
    endpoint: "unix:///var/run/docker.sock"
    watchByDefault: true
    watchStopped: true
EOF
sudo ln -s /etc/diun/diun.yml
sudo chmod 644 /etc/diun/diun.yml


echo "______________________________________________________"
echo "           OPTIONAL TOOLS OR CONFIGURATIONS           "
echo "______________________________________________________"
echo "--------------------------------------------------------------------------------------------------------------"
echo "Download recommended/best-practices configuration for QBittorrent: to download media, torrents? (recommended)" 
read -p "y or n ?" answer
case ${answer:0:1} in
    y|Y )
        sudo mkdir -p $HOME/docker/qbittorrent/config
        sudo chown ${USER}:${USER} $HOME/docker/qbittorrent/config
        wget -O $HOME/docker/qbittorrent/config/qBittorrent.conf https://raw.githubusercontent.com/zilexa/Homeserver/master/docker/qbittorrent/config/qBittorrent.conf
        sudo chmod 644 $HOME/docker/qbittorrent/config/qBittorrent.conf
    ;;
    * )
        echo "SKIPPED downloading QBittorrent config file.."
    ;;
esac


echo "--------------------------------------------------------------------------------------------------------------"
echo "Get the PIA VPN script to auto-update Qbittorrent portforwarding? (recommended if you will use PIA VPN for downloads)" 
read -p "y or n ?" answer
case ${answer:0:1} in
    y|Y )
        echo " PIA VPN script to auto-update Qbittorrent  "
        echo "--------------------------------------------"
        mkdir -p $HOME/docker/vpn-proxy/pia-shared
        wget -O $HOME/docker/vpn-proxy/pia-shared/updateport-qb.sh https://raw.githubusercontent.com/zilexa/Homeserver/master/docker/vpn-proxy/pia-shared/updateport-qb.sh
        chmod +x $HOME/docker/vpn-proxy/pia-shared/updateport-qb.sh
        echo "DONE! Don't forget to enter your QBittorrent credentials in the script after you have changed them in the webUI"
        echo "(default is admin/adminadmin)."
    ;;
    * )
        echo "SKIPPED getting PIA VPN script for auto-updating QB portforwarding.."
    ;;
esac


echo "Install SNAPRAID-BTRFS for parity-based backups? (recommended if you will pool drives via MergerFS instead of BTRFS RAID)"
read -p "y or n ?" answer
case ${answer:0:1} in
    y|Y )
        echo "Installing required tools: snapraid, Snapraid-btrfs, snapraid-btrfs-runner mailscript and snapper.."
        sudo pamac install --no-confirm snapraid 
        sudo pamac install --no-confirm snapraid-btrfs-git
        # Install snapraid-btrfs-runner
        wget -O $HOME/docker/HOST/snapraid/master.zip https://github.com/fmoledina/snapraid-btrfs-runner/archive/refs/heads/master.zip
        unzip $HOME/docker/HOST/snapraid/master.zip
        mv $HOME/docker/HOST/snapraid/snapraid-btrfs-runner-master $HOME/docker/HOST/snapraid/snapraid-btrfs-runner
        rm $HOME/docker/HOST/snapraid/master.zip
        # Install snapper, required for snapraid-btrfs 
        sudo pamac install --no-confirm snapper-gui
        # Get snapper default template
        sudo wget -O /etc/snapper/config-templates/default https://raw.githubusercontent.com/zilexa/Homeserver/master/docker/HOST/snapraid/snapper/default
        # get SnapRAID config
        sudo wget -O $HOME/docker/HOST/snapraid/snapraid.conf https://raw.githubusercontent.com/zilexa/Homeserver/master/docker/HOST/snapraid/snapraid.conf
        sudo ln -s $HOME/docker/HOST/snapraid/snapraid.conf /etc/snapraid.conf
        # DONE !
        # MANUALLY: Create a root subvolume on your fastest drives named .snapraid, this wil contain snapraid content file. 
        # MANUALLY: customise the $HOME/docker/HOST/snapraid/snapraid.conf file to your needs. 
        # MANUALLY: follow instructions in the guide 
        # Get drive IDs
        #ls -la /dev/disk/by-id/ | grep part1  | cut -d " " -f 11-20
    ;;
    * )
        echo "Skipping Snapraid, Snapraid-BTRFS, snapraid-btrfs-runner and snapper"
    ;;
esac

echo "                                                                               "        
echo "==============================================================================="
echo "                                                                               "  
echo "  All done! Please reboot and do not use sudo for docker or compose commands.  "
echo "                                                                               "  
echo "==============================================================================="
