# check if running as root
[[ $EUID -ne 0 ]] && {
    echo "This script must be run as root."
    exit
}

# Nvidia is a non-free software
apt-add-repository non-free

DEBIAN_FRONTEND=noninteractive apt-get -qq update && apt-get -qq upgrade

echo "blacklist nouveau" > /etc/modprobe.d/blacklist-nvidia-nouveau.conf 
echo "options nouveau modeset=0" >> /etc/modprobe.d/blacklist-nvidia-nouveau.conf

# ensure we have the needed packages
DEBIAN_FRONTEND=noninteractive apt-get -qq install pkg-config
DEBIAN_FRONTEND=noninteractive apt-get -qq install libglvnd-dev
DEBIAN_FRONTEND=noninteractive apt-get -qq install linux-headers-$(uname -r) build-essential

systemctl set-default multi-user.target

[ ! -f /usr/local/bin/runonetime-nvidia-installer.sh ] && {

echo "#!/bin/bash

cd /root
curl -L https://us.download.nvidia.com/XFree86/Linux-x86_64/460.67/NVIDIA-Linux-x86_64-460.67.run -o nvidiadriver.run
chmod u+x nvidiadriver.run
./nvidiadriver.run -s

grep -q '^GRUB_GFXMODE' && sed -i 's/^GRUB_GFXMODE/GRUB_GFXMODE=1280x800x32/' /etc/default/grub || echo 'GRUB_GFXMODE=1280x800x32' >> /etc/default/grub
grep -q '^GRUB_GFXPAYLOAD_LINUX' && sed -i 's/^GRUB_GFXPAYLOAD_LINUX/GRUB_GFXPAYLOAD_LINUX=1920x1200x32/' /etc/default/grub || echo 'GRUB_GFXPAYLOAD_LINUX=1920x1200x32' >> /etc/default/grub

grub-mkconfig -o /boot/grub/grub.cfg

update-initramfs -u
systemctl set-default graphical.target

[ -f /usr/local/bin/runonetime-nvidia-installer.sh ] && rm /usr/local/bin/runonetime-nvidia-installer.sh
[ -f /etc/systemd/system/runonetime-nvidia-installer.service ] && rm /etc/systemd/system/runonetime-nvidia-installer.service

systemctl disable runonetime-nvidia-installer.service

reboot
" > /usr/local/bin/runonetime-nvidia-installer.sh
    chmod +x /usr/local/bin/runonetime-nvidia-installer.sh
}

echo "[Unit]
Description=Simple one time run
Requires=network-online.target
After=multi-user.target network-online.target systemd-networkd.service

[Service]
Type=simple
ExecStart=/usr/local/bin/runonetime-nvidia-installer.sh

[Install]
WantedBy=default.target
" > /etc/systemd/system/runonetime-nvidia-installer.service

systemctl daemon-reload
systemctl enable runonetime-nvidia-installer.service

update-initramfs -u

reboot
