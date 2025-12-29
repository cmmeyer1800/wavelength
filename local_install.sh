#!/bin/bash

if [ $# -ne 1 ]; then
    echo "Usage: install.sh PATH_TO_WL_SH"
    exit 1
fi

WL_SH_PATH="$1"

mkdir -p ~/.wavelength
cp "$WL_SH_PATH" ~/.wavelength/wl.sh

echo "Successfully installed wavelength
Add the follwing to your bash/zc/etc .rc:
    source ~/.wavelength/wl.sh"
