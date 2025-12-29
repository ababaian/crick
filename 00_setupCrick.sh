#!/bin/bash
#
# Crick System Initalization - 251226
# off of Ubuntu 25.10 Server
# (code + pseudocode)
set -e

sudo apt update
sudo apt-get install ubuntu-desktop-minimal

# BUG FIX ----------------------------------------------------
# ============================================================

# fix DNS issue
sudo mkdir -p /etc/systemd/resolved.conf.d
sudo tee /etc/systemd/resolved.conf.d/override.conf >/dev/null <<'EOF'
[Resolve]
DNS=1.1.1.1 8.8.8.8
FallbackDNS=9.9.9.9
Domains=~.
EOF
sudo systemctl restart systemd-resolved

# fix wifi issue
# Disable Wi-Fi power saving (root cause)
sudo tee /etc/NetworkManager/conf.d/wifi-powersave.conf >/dev/null <<'EOF'
[connection]
wifi.powersave = 2
EOF

# Prevent suspend targets (harmless, explicit)
sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target

# Restart networking cleanly
sudo systemctl restart NetworkManager

# Core utils
sudo apt-get install git

# Gnome Remote Desktop
sudo systemctl set-default graphical.target
sudo reboot
# sudo nano /etc/gdm3/custom.conf
## [daemon]
## AutomaticLoginEnable=true
## AutomaticLogin=rnalab

# ============================================================
# CRICK UI
# ============================================================
mkdir -p ~/Modules ; cd Modules

# Core multimedia + codecs
sudo apt install -y \
  vlc \
  ubuntu-restricted-extras \
  ffmpeg

mkdir -p ./crickController; cd crickController # ------------
  # Keyboard Controller
  sudo apt install -y evtest
  sudo apt install interception-tools

  # 01_crickKeyboard.sh
  # 01_crickKeyboard.yaml

cd .. # End Crick Controller ---------------------------------

cd ~/Videos/ # -----------------------------------------------

mkdir -p simpsons; cd simpsons

  cp S08E01.Treehouse.of.Horror.VII.mkv ./ 
  cp S08E01.Treehouse.of.Horror.VII.mkv ./
  cp S08E12.Mountain.of.Madness.mkv ./
  cp S08E09.El.Viaje.Misterioso.de.Nuestro.Jomer.mkv ./
  cp S08E23.Homers.Enemy.mkv ./
  cp S08E10.The.Springfield.Files.mkv ./

  cd ..

mkdir -p msb; cd msb
  #  Magic School Bus
  #  https://en.wikipedia.org/wiki/List_of_The_Magic_School_Bus_episodes
  cp 'E03 - Inside Ralphie [Germs].mp4' ./
  cp 'E39 - Holiday Special [Recycling].mp4' ./
  cp 'E20 - In a Pickle [Microbes].mp4' ./
  cp 'E50 - Gets Programmed [Computers].mp4' ./

cd ..

## ReGenesis (TBD)

## MOVIES
mkdir -p film; cd film

  cp Gattaca.mkv ./

cd ..


cd .. # End Videos/ ------------------------------------------

# Fun utils
sudo apt-get install sl
sudo apt-get install cmatrix # matrix emulator
sudo apt-get install aview # asciiview png to ascii
sudo apt-get install tty-clock # ascii clock
  #  tty-clock -brs -C 3
# Doom

# Webcam → stream / virtual camera tools
sudo apt install -y \
  v4l2loopback-dkms \
  v4l-utils
  #mjpg-streamer #SNAP

# Science / visualization
sudo apt install -y \
  pymol

# Terminal + emulation
sudo apt install -y cool-retro-term

# ============================================================
# GAMING
# ============================================================

# mupen64plus-qt Needs work

# Input controllers
sudo apt install -y \
  joystick \
  evtest \
  qjoypad

# Enable v4l2 loopback (virtual webcam)
sudo modprobe v4l2loopback devices=1 video_nr=10 card_label="VirtualCam" exclusive_caps=1

echo
echo "Install complete."
echo "Reboot recommended for codecs and v4l2loopback."

# DOOM
mkdir -p ~/doom; cd ~/doom
#sudo apt install -y doom-ascii
sudo apt-get install -y crispy-doom

# Using /home/rnalab/.local/share/crispy-doom/ for configuration and saves


# ============================================================
# Samba setup for Ubuntu (Pi)
# - Creates a password-protected SMB share
# - Share path: /home/ubuntu/share
# - User: ubuntu
# ============================================================

# --- Install Samba ---
sudo apt update
sudo apt install -y samba

# --- Create shared directory ---
SHAREDIR='/home/rnalab'

# --- Backup existing Samba config ---
sudo cp /etc/samba/smb.conf /etc/samba/smb.conf.bak

# --- Append Samba share configuration ---
sudo tee -a /etc/samba/smb.conf >/dev/null <<'EOF'

# ========================
# Custom Pi Samba Share
# ========================
[share]
   path = /home/rnalab
   browseable = yes
   read only = no
   guest ok = no
   valid users = rnalab

# Enforce modern SMB (disable SMB1)
[global]
   server min protocol = SMB2
EOF

# --- Set Samba password for user ubuntu ---
echo "Set Samba password for user 'rnalab':"
sudo smbpasswd -a rnalab
sudo smbpasswd -e rnalab

# --- Restart Samba services ---
sudo systemctl restart smbd
sudo systemctl enable smbd

# --- Local test (optional) ---
echo
echo "Testing Samba configuration:"
smbclient -L localhost -U ubuntu || true

# --- Done ---
echo
echo "Samba setup complete."
echo "Access from another machine using:"
echo "  smb://retro-pi.local/share"