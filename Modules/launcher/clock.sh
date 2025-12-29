#!/usr/bin/env bash
set -euo pipefail
CFG="${HOME}/Desktop/crick/config/rnalab_i.coolterm.json"

# Minimize all existing windows (ignore failure if none exist)
wmctrl -k on  >/dev/null 2>&1 || true
wmctrl -k off >/dev/null 2>&1 || true

exec cool-retro-term \
	-c $CFG --fullscreen \
	-T Clock \
	-e tty-clock -brs -C 4
