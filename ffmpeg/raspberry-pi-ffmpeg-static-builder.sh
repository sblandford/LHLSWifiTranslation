#!/bin/bash


set -e
TARGET_DIR="$( pwd )/static_build"
TOOLS_DIR_BASENAME="x-tools"
TOOLS_DIR="$( pwd )/$TOOLS_DIR_BASENAME"
THREADS=$( grep -c "^processor" /proc/cpuinfo )


if [[ "$1" == "clean" ]]; then
    rm -rf "$TOOLS_DIR" ".build" "crosstool-ng"
    rm -f .config.old build.log
    ./ffmpeg-static-builder.sh clean
    exit
fi

if ! echo "$PATH" | grep -qF "$TARGET_DIR"; then
    export PATH="$PATH:$TARGET_DIR/bin"
fi

if [[ ! -f "$TOOLS_DIR/arm-rpi-linux-gnueabihf/bin/arm-rpi-linux-gnueabihf-gcc" ]]; then

    installed=$( apt list --installed 2>/dev/null )
    for package in $( echo help2man libtool-bin libtool-doc texinfo pkg-config ); do
        if ! echo "$installed" | grep -qiP "^$package/"; then
            echo "$package not there"
            #sudo apt install -y help2man libtool-bin libtool-doc texinfo pkg-config
            #break
        fi
    done

    if [[ ! -d "crosstool-ng" ]]; then
        git clone https://github.com/crosstool-ng/crosstool-ng crosstool-ng
    fi
    (
        cd "crosstool-ng"
        if [[ ! -f configure ]]; then
            ./bootstrap
        fi
        ./configure --prefix="$TARGET_DIR"
        nice -n 20 make -j $THREADS
        nice -n 20 make -j $THREADS install
    )
    ulimit -n 4096
    mkdir -p "$TOOLS_DIR/src"

    ct-ng build

    # sudo chown -R "$USER": .
    chmod -R a+w .
fi
if ! echo "$PATH" | grep -qF "$TOOLS_DIR_BASENAME/arm-rpi-linux-gnueabihf/bin"; then
    export PATH="$PATH:$TOOLS_DIR/arm-rpi-linux-gnueabihf/bin"
fi
export CCPREFIX="$TOOLS_DIR/arm-rpi-linux-gnueabihf/bin/arm-rpi-linux-gnueabihf-"

./ffmpeg-static-builder.sh
