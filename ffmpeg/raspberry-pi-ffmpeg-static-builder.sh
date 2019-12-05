#!/bin/bash


set -e
TARGET_DIR="$( pwd )/static_build"

sudo apt install -y help2man libtool-bin libtool-doc texinfo pkg-config

if [[ ! -d "crosstool-ng" ]]; then
    git clone https://github.com/crosstool-ng/crosstool-ng crosstool-ng
fi
(
    cd "crosstool-ng"
    if [[ ! -f bootstrap ]]; then
        ./bootstrap
    fi
    ./configure --prefix="$TARGET_DIR"
    nice -n 20 make -j 8
    nice -n 20 make -j 8 install
)
if ! echo "$PATH" | grep -qF "$TARGET_DIR"; then
    export PATH="$PATH:$TARGET_DIR/bin"
fi

ulimit -n 4096
ct-ng build

