#!/bin/bash
# set -e
#
# Crick System Presets - 251226
# Requires evtest

# Input Controller Map ====
# +---+---+---+---+
# | A | B | C | D |   ( 2 )
# +---+---+---+---+
# | E | F | G | H |
# +---+---+---+---+
# | I | J | K | L |   ( 5 )
# +---+---+---+---+

## Modules ----------------

# A : Biohazard : sl
# B : Rabbit : PETase slide deck
# C : Kitten : piPET
# D : Cow : clock

# E : Radioactive : ASCII Art Gallary
# F : RedBow : Simpsons
# G : Bluebow : Magic School Bus
# H : Star : GATTACA

# I : Cappuccino :
# J : Cone : <open_slot>
# K : Americano : <open_slot>
# L : Cake : <open_slot>

## UNUSED

# cmatrix
# doom
# SNES Roms
# N64 Roms
# Check out 4273pi.tar.gz (https://4273pi.org)

# Screensaver

# KNOBS====================
KNOB_A_CCW='KEY_1'
KNOB_A_PRESS='KEY_2'
KNOB_A_CW='KEY_3'


KNOB_B_CCW='KEY_4'
KNOB_B_PRESS='KEY_5'
KNOB_B_CW='KEY_6'

DEVICE_PATH='' # Stable device path (preferred)
EVENT_NODE='' # Kernel event device (informational)
USB_ID='' # Vendor ID from lsusb


# ============================================================
# Bind KEY_X to run commands
#
# Method:
# - Listen to the controller via evtest
# - Detect KEY_A press (value 1)
# - Run a shell command
#
# Notes:
# - Works over SSH
# - No GUI required
# - Uses stable /dev/input/by-id path
# ============================================================

# -------- CONFIG --------

# Replace this with your controller's stable device path
# Find it via: ls -l /dev/input/by-id/
DEVICE="/dev/input/event0"

# Command to run when KEY_A is pressed
A_CMD="touch ~/Desktop/tmp"

# -------- EVENT LOOP --------

sudo evtest "$DEVICE" | \
while read -r line; do
  # Look for KEY_A press (value 1 = key down)
  if echo "$line" | grep -q "EV_KEY.*KEY_A.*value 1"; then
    echo "[ACTION] KEY_A pressed → running command"
    eval "$A_CMD"
  fi
done


# ============================================================
# piPET Visual Display
# ============================================================

# ============================================================
# PETadex slide deck
# ============================================================

# ============================================================
# 80s/90s Video Playback
# ============================================================

# cd ~/Videos/ # -----------------------------------------------

# mkdir -p simpsons; cd simpsons

# cp S08E01.Treehouse.of.Horror.VII.mkv ./ 
# cp S08E01.Treehouse.of.Horror.VII.mkv ./
# cp S08E12.Mountain.of.Madness.mkv ./
# cp S08E09.El.Viaje.Misterioso.de.Nuestro.Jomer.mkv ./
# cp S08E23.Homers.Enemy.mkv ./
# cp S08E10.The.Springfield.Files.mkv ./

# cd ..

# mkdir -p msb; cd msb
# #  Magic School Bus

# cp 'E03 - Inside Ralphie [Germs].mp4' ./
# cp 'E39 - Holiday Special [Recycling].mp4' ./
# cp 'E20 - In a Pickle [Microbes].mp4' ./
# cp 'E50 - Gets Programmed [Computers].mp4' ./

# ## ReGenesis (TBD)

# ## MOVIES
# mkdir -p film; cd film

# cp Gattaca.mkv ./

# cd ..


# cd .. # End Videos/ ------------------------------------------
# ============================================================
# Music w/ Equializer
# ============================================================

# QMMP with ProjectM
# bmelgren -Godhead.milk

# ============================================================
# Smash Bros 64
# ============================================================

# ============================================================
# MarioKart 64
# ============================================================

# ============================================================
# Starfox 64
# ============================================================

# ============================================================
# DOOM + ASCII
# ============================================================

# crispy-doom

# ============================================================
# Game of Life
# ============================================================

# ============================================================
# ASCII Art
# ============================================================