#!/bin/bash

if [ $# -ne 1 ]; then
    echo "Usage: install.sh PATH_TO_WL_SH"
    exit 1
fi

WL_SH_PATH="$1"
INSTALL_DIR="${WL_BASE_DIR:-$HOME/.wavelength}"

mkdir -p "$INSTALL_DIR"
cp "$WL_SH_PATH" "$INSTALL_DIR/wl.sh"

echo "Successfully installed wavelength
Add the following to your bash/zsh/etc .rc:
    source \"$INSTALL_DIR/wl.sh\""
