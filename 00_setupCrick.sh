#!/bin/bash
# ==============================================================================
# Crick: Blank-slate install on Raspberry Pi + Ubuntu 25.10 Desktop
# version: 20251229
#
# Usage after first boot + login:
#   1) sudo apt update && sudo apt install -y git
#   2) git clone https://github.com/ababaian/crick.git ~/crick
#   3) cd ~/crick
#   4) bash 00_setupCrick.sh
#
# ==============================================================================
set -euo pipefail

# USER Details
CRICK_USER="${SUDO_USER:-$USER}"                          # user:  rnalab
CRICK_HOME="$(getent passwd "$CRICK_USER" | cut -d: -f6)" # home:  /home/rnalab
CRICK_HOSTNAME="${CRICK_HOSTNAME:-rnalab-pi}"             # host:  rnalab-pi
SAMBA_SHARE_NAME="${SAMBA_SHARE_NAME:-share}"             # samba: rnalab
SAMBA_SHARE_PATH="${SAMBA_SHARE_PATH:-$CRICK_HOME}"       # default: your home
SAMBA_VALID_USER="${SAMBA_VALID_USER:-$CRICK_USER}"

# Set Need Reboot Flag
need_reboot=0

log() { echo -e "[crick] $*"; }

# ============================================================
# CRICK SYSTEM + NETWORK
# ============================================================
log "Updating apt indexes..."
sudo apt-get update -y

log "Enable SSH Login"
sudo apt install -y openssh-server
  sudo systemctl enable --now ssh
  systemctl status ssh --no-pager

log "Installing core packages..."
sudo apt-get install -y \
  git curl ca-certificates unzip jq \
  network-manager vim

# Prevent Auto-starting Unattended Upgrades (locks)
sudo systemctl disable unattended-upgrades

# DNS override (idempotent)
# Force stable, known-good DNS resolvers for the system (Cloudflare + Google),
# avoiding flaky ISP/router DNS common on Pi Wi-Fi setups.
# Uses systemd-resolved drop-in config so it is safe, persistent, and idempotent.

log "Configuring systemd-resolved DNS override..."
sudo mkdir -p /etc/systemd/resolved.conf.d
sudo tee /etc/systemd/resolved.conf.d/crick-dns.conf >/dev/null <<'EOT'
[Resolve]
DNS=1.1.1.1 8.8.8.8
FallbackDNS=9.9.9.9
Domains=~.
EOT
sudo systemctl restart systemd-resolved || true

# Wi-Fi powersave off (idempotent)
# Disable Wi-Fi power saving to prevent random disconnects and latency spikes,
# which are common on Raspberry Pi adapters under NetworkManager.
# Uses a NetworkManager drop-in so it persists across reboots and updates.
log "Disabling Wi-Fi powersave..."
sudo mkdir -p /etc/NetworkManager/conf.d
sudo tee /etc/NetworkManager/conf.d/crick-wifi-powersave.conf >/dev/null <<'EOT'
[connection]
wifi.powersave = 2
EOT
sudo systemctl restart NetworkManager || true

# Optional: prevent sleep on a kiosk-like station (idempotent)
# Prevent the system from suspending, hibernating, or sleeping like a laptop.
# Ensures Crick behaves as an always-on appliance / kiosk when unattended.
# Masking systemd targets is safe, reversible, and survives upgrades.
log "Masking sleep/suspend targets (kiosk behavior)..."
sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target >/dev/null 2>&1 || true

# Set hostname (optional but reproducible)
# Set a deterministic hostname so the Pi is discoverable on the network
# (SSH, Samba, mDNS) under a predictable name.
# Marks reboot only if the hostname actually changes.
if [[ -n "${CRICK_HOSTNAME}" ]]; then
  cur="$(hostnamectl --static status 2>/dev/null || hostname)"
  if [[ "$cur" != "$CRICK_HOSTNAME" ]]; then
    log "Setting hostname to: $CRICK_HOSTNAME"
    sudo hostnamectl set-hostname "$CRICK_HOSTNAME"
    need_reboot=1
  fi
fi

# ============================================================
# Remote Desktop (GNOME Remote Desktop via RDP)
# ============================================================
#
# xfreerdp /v:192.168.0.52 /u:rnalab=
#
# Purpose:
# - Enable GNOME's built-in RDP server (no xrdp needed)
# - Generate a self-signed TLS cert so RDP doesn't reset during TLS negotiation
# - Optionally set credentials via grdctl (preferred when available)
#
# Note:
# - systemctl --user requires an active user session (Desktop login). If run over
#   sudo/SSH without a session, we skip gracefully.

log "Remote Desktop: installing prerequisites..."
sudo apt-get install -y openssl gnome-remote-desktop || true

# Enable GNOME Remote Desktop service (skip if no user systemd session)
if systemctl --user status >/dev/null 2>&1; then
  log "Remote Desktop: enabling gnome-remote-desktop user service..."
  systemctl --user enable --now gnome-remote-desktop.service || true
else
  log "Remote Desktop: no user systemd session; skipping service enable (run after GUI login)."
fi

# --- TLS cert/key (fixes 'certificate invalid' + connection reset) ---
TLS_DIR="$HOME/.local/share/gnome-remote-desktop"
mkdir -p "$TLS_DIR"

CRT="$TLS_DIR/rdp-tls.crt"
KEY="$TLS_DIR/rdp-tls.key"

if [[ ! -s "$CRT" || ! -s "$KEY" ]]; then
  log "Remote Desktop: generating self-signed RDP TLS cert/key..."
  openssl req -x509 -newkey rsa:2048 -sha256 -days 3650 -nodes \
    -keyout "$KEY" \
    -out   "$CRT" \
    -subj "/CN=$(hostname)"
  chmod 600 "$KEY"
  chmod 644 "$CRT"
fi

# Configure TLS + credentials if grdctl exists; otherwise document GUI method
if command -v grdctl >/dev/null 2>&1; then
  log "Remote Desktop: configuring GNOME RDP TLS + credentials via grdctl..."
  grdctl rdp set-tls-cert "$CRT" || true
  grdctl rdp set-tls-key  "$KEY" || true
  grdctl rdp enable || true
  grdctl rdp disable-view-only || true

  echo
  echo "[crick] Set RDP credentials (stored in your user secret store):"
  read -r -s -p "RDP password to set for '$USER': " RDP_PASS; echo
  grdctl rdp set-credentials "$USER" "$RDP_PASS" || true
else
  log "Remote Desktop: grdctl not found; configure RDP via GUI once:"
  cat <<'EOT'
[crick] GUI step (one-time):
  Settings → System → Remote Desktop
    - Enable Remote Desktop
    - Enable Remote Login
    - Select RDP
    - Set a Remote Desktop password
EOT
fi

# Restart + verify (don’t hard-fail)
if systemctl --user status >/dev/null 2>&1; then
  log "Remote Desktop: restarting gnome-remote-desktop..."
  systemctl --user restart gnome-remote-desktop.service || true
fi

log "Remote Desktop: check listener + logs (optional):"
ss -tulpn | grep -E ':3389\b' || true
journalctl --user -u gnome-remote-desktop -n 30 --no-pager 2>/dev/null || true


# ============================================================
# CRICK UI
# ============================================================
log "Installing multimedia + terminal apps..."

# Multimedia + Codecs
sudo apt-get install -y \
  vlc ffmpeg ubuntu-restricted-extras

# Crick and Crick Controller Dependencies
  sudo apt install -y \
  evtest interception-tools wmctrl

# Terminal + emulation
sudo apt install -y \
  cool-retro-term

# Fun utils
sudo apt-get install sl
sudo apt-get install cmatrix # matrix emulator
sudo apt-get install aview # asciiview png to ascii
sudo apt-get install tty-clock # ascii clock - tty-clock -brs -C 3
# TODO: Doom

# Science / visualization
sudo apt install -y \
  pymol

# cd ~/Videos/ # -----------------------------------------------

# mkdir -p simpsons; cd simpsons

#   cp S08E01.Treehouse.of.Horror.VII.mkv ./ 
#   cp S08E01.Treehouse.of.Horror.VII.mkv ./
#   cp S08E12.Mountain.of.Madness.mkv ./
#   cp S08E09.El.Viaje.Misterioso.de.Nuestro.Jomer.mkv ./
#   cp S08E23.Homers.Enemy.mkv ./
#   cp S08E10.The.Springfield.Files.mkv ./

#   cd ..

# mkdir -p msb; cd msb
#   #  Magic School Bus
#   #  https://en.wikipedia.org/wiki/List_of_The_Magic_School_Bus_episodes
#   cp 'E03 - Inside Ralphie [Germs].mp4' ./
#   cp 'E39 - Holiday Special [Recycling].mp4' ./
#   cp 'E20 - In a Pickle [Microbes].mp4' ./
#   cp 'E50 - Gets Programmed [Computers].mp4' ./

# cd ..

# ## ReGenesis (TBD)

# ## MOVIES
# mkdir -p film; cd film

#   cp Gattaca.mkv ./

# cd ..

# End Videos/ ------------------------------------------


# ============================================================
# GAMING
# ============================================================
# See: https://docs.libretro.com/guides/core-list/#

# Input/Output
sudo apt install -y \
  joystick \
  evtest \
  qjoypad

# mupen64plus-qt Needs work

# SNES9x emulator
wget https://github.com/snes9xgit/snes9x/releases/download/1.63/Snes9x-1.63-x86_64.AppImage
mv Snes9x-1.63-x86_64.AppImage snes9x
chmod 755 snes9x
mv snes9x /usr/games/

# higen SNES emulator
sudo apt install libgtksourceview2.0-0

# wget https://github.com/higan-emu/higan/releases/download/v110/higan-v110-linux-x86_64.zip
# unzip higan-v110-linux-x86_64.zi
# unzip higan-nightly
sudo cp higan-nightly/higan /usr/games/
sudo cp higan-nightly/icarus /usr/games/
sudo cp higan-nightly/genius /usr/games/
# /usr/games/ (Run which mupen64plus and move icarus higen and genius to that dir)


# DOOM
mkdir -p ~/doom; cd ~/doom
#sudo apt install -y doom-ascii
sudo apt-get install -y crispy-doom

# Using /home/rnalab/.local/share/crispy-doom/ for configuration and saves

# ============================================================
# WEBCAM
# ============================================================

# Webcam → stream / virtual camera tools
sudo apt install -y \
  v4l2loopback-dkms \
  v4l-utils
  #mjpg-streamer #SNAP

log "Configuring v4l2loopback to load at boot..."
sudo tee /etc/modules-load.d/crick-v4l2loopback.conf >/dev/null <<'EOT'
v4l2loopback
EOT

sudo tee /etc/modprobe.d/crick-v4l2loopback.conf >/dev/null <<'EOT'
options v4l2loopback devices=1 video_nr=10 card_label="VirtualCam" exclusive_caps=1
EOT

# Try loading now (won't fail the run)
sudo modprobe v4l2loopback >/dev/null 2>&1 || true
need_reboot=1


# Enable v4l2 loopback (virtual webcam)
sudo modprobe v4l2loopback devices=1 video_nr=10 card_label="VirtualCam" exclusive_caps=1


# ============================================================
# Samba setup for Ubuntu (Pi)
# - Creates a password-protected SMB share
# - Share path: /home/ubuntu/share
# - User: ubuntu
# ============================================================

# --- Install Samba ---
sudo apt update
sudo apt install -y samba

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
# echo
# echo "Testing Samba configuration:"
# smbclient -L localhost -U ubuntu || true

# --- Done ---
echo
echo "Samba setup complete."
echo "Access from another machine using:"
echo "  smb://rnalab-pi.local/share"