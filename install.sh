#!/bin/sh

VERSION="0.1.1"
SCRIPT_URL="https://github.com/cmmeyer1800/wavelength/releases/download/v$VERSION/wl.sh"

# Try curl first, if not available try wget
if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$SCRIPT_URL" -o wl.sh
elif command -v wget >/dev/null 2>&1; then
    wget -q "$SCRIPT_URL" -O wl.sh
else
    echo "Error: Neither curl nor wget is installed. Please install one of these tools to proceed."
    exit 1
fi

mkdir -p ~/.wavelength

chmod +x wl.sh
mv wl.sh ~/.wavelength/wl.sh

echo "Successfully installed wavelength
Add the following to your bash/zsh/etc .rc:
    source ~/.wavelength/wl.sh"
