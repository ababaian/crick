#!/bin/bash
# Crick Pi Main Launcher - Text-Based UI Loop

# Configuration
ASCII_DIR="~/Pictures"           # directory containing ASCII art files
MODULE_LOADING_ART="$ASCII_DIR/splash1.txt"  # ASCII art to display on module loading
IDLE_TIMEOUT=60                  # seconds of no input before screensaver
MOCK_INPUT=true                  # if no physical controller, use keyboard (numpad keys 1-9, /, *, -)

# Splash Screen -------------------------------------------

# Ensure ASCII art directory exists; fall back to plain text if not
shopt -s nullglob

if [[ ! -d "$ASCII_DIR" ]]; then
  ASCII_FILES=()
else
  ASCII_FILES=("$ASCII_DIR"/*.txt)
fi

# Helper: draw splash (ASCII if available, else fallback text)
draw_splash() {
  clear
  if (( ${#ASCII_FILES[@]} > 0 )); then
    cat "${ASCII_FILES[RANDOM % ${#ASCII_FILES[@]}]}"
  else
    cat <<'EOF'
=====================
  Booting CRICK pi
=====================
EOF
  fi
  wait 2s
}

# Main loop -----------------------------------------------
# Run kiosk indefinitely

while true; do
  clear
  # Show a random ASCII splash art (for initial loop, can be the main logo)
  files=("$ASCII_DIR"/*.txt)
  if (( ${#files[@]} > 0 )); then
    # Pick a random ASCII art file to display as the splash
    splash_file="${files[RANDOM % ${#files[@]}]}"
    cat "$splash_file"
  else
    echo "~~ CRICK Pi ~~"
  fi

  # Display menu options (list keys for available modules)
  echo ""
  echo "Select an option (press corresponding key):"
  echo " 1 - Number Guessing Game"
  echo " 2 - ASCII Art Slideshow"
  # (Other keys 3-9,/,*,- can be mapped to future modules)
  echo "  Q - Quit (if running in a terminal session)"

  # Wait for user input or timeout for screensaver
  if $MOCK_INPUT; then
    # Read one key from keyboard (numpad keys or Q to exit)
    read -t $IDLE_TIMEOUT -n1 selection
  else
    # In real controller scenario, read from controller device or similar (not implemented)
    read -t $IDLE_TIMEOUT -n1 selection
  fi

  # If timed out (no input), launch screensaver
  if [[ -z "$selection" ]]; then
    ./clock.sh   # run the clock screensaver (exits on keypress)
    # After clock exits (user pressed a key), continue loop to redraw menu
    continue
  fi

  # If user pressed Q or q, allow exit from the launcher (for debugging or terminal use)
  if [[ "$selection" =~ ^[Qq]$ ]]; then
    echo ""
    echo "Exiting Crick Pi launcher..."
    break
  fi

  # Handle selection
  clear
  case "$selection" in
    1)  # Number Guessing Game module
        # Display module loading screen with ASCII art
        cat "$MODULE_LOADING_ART"
        echo -e "\n[ Loading Number Guessing Game... ]"
        sleep 2
        ./module1.sh
        ;;
    2)  # ASCII Art Slideshow module
        cat "$MODULE_LOADING_ART"
        echo -e "\n[ Loading ASCII Art Slideshow... ]"
        sleep 2
        ./slideshow.sh
        ;;
    [3-9] | '/' | '*' | '-' )
        echo "Module for key '$selection' is not implemented yet."
        echo "Press any key to return to menu."
        read -n1 -s  # wait for a key press
        ;;
    *)  # Unrecognized input (not a valid selection)
        echo "Unknown selection: '$selection'"
        echo "Press any key to continue."
        read -n1 -s
        ;;
  esac
  # Loop back to show menu again after module exits
done