#!/bin/bash
# Build static FFMPEG with ALSA and FDK AAC support

set -e
TARGET_DIR="$( pwd )/static_build"
DOCKER_FFMPEG="lhls_encoder/root/usr/local/bin/ffmpeg"
THREADS=$( grep -c "^processor" /proc/cpuinfo )

if [[ "$1" == "clean" ]]; then
    rm -rf "alsa-lib" "fdk-aac" "ffmpeg" "$TARGET_DIR"
    exit
fi

if pwd | grep -qP "\s"; then
    echo "Current working directory, $pwd, can not have spaces in it due to bugs in library build"
    exit 1
fi

mkdir -p "$TARGET_DIR"

if [[ ! -d "alsa-lib" ]]; then
    git clone git://git.alsa-project.org/alsa-lib.git alsa-lib
fi
if [[ ! -f "$TARGET_DIR/lib/libasound.a" ]]; then
    (
        cd alsa-lib
        make clean &>/dev/null || echo
        echo "Alsa config"
        libtoolize --force --copy --automake
        aclocal
        autoheader
        automake --foreign --copy --add-missing
        autoconf
        if [[ $CCPREFIX ]]; then
            # TODO Always compiling to x86 no matter what
            ./configure --host=arm-rpi-linux-gnueabihf --prefix="$TARGET_DIR" --enable-static=yes --enable-shared=no
        else
            ./configure --prefix="$TARGET_DIR" --enable-static=yes --enable-shared=no
        fi
        echo "Alsa build"
        nice -n 20 make -j $THREADS
        echo "Alsa install"
        make install
    )
fi
if [[ ! -d "fdk-aac" ]]; then
    git clone --depth 1 https://github.com/mstorsjo/fdk-aac fdk-aac
fi
if [[ ! -f "$TARGET_DIR/lib/libfdk-aac.a" ]]; then
    (
        cd fdk-aac
        make clean &>/dev/null || echo
        echo "FDK AAC config"
        ./autogen.sh --host=arm-unknown-linux-gnueabi
        if [[ $CCPREFIX ]]; then
            # TODO Always compiling to x86 no matter what
            ./configure --host=arm-rpi-linux-gnueabihf --prefix="$TARGET_DIR" --disable-shared
        else
            ./configure --prefix="$TARGET_DIR" --disable-shared
        fi
        echo "FDK AAC compile"
        nice -n 20 make -j $THREADS
        echo "FDK AAC install"
        make install
    )
fi
if [[ ! -d "ffmpeg" ]]; then
    git clone https://git.ffmpeg.org/ffmpeg.git ffmpeg
fi
(
    cd ffmpeg
    make clean &>/dev/null || echo
    echo "FFMEG Config"

    if [[ $CCPREFIX ]]; then
        pkg_config=$( which pkg-config ) PKG_CONFIG_PATH="$TARGET_DIR/lib/pkgconfig" ./configure \
            --enable-cross-compile --cross-prefix=${CCPREFIX} --arch=armel --target-os=linux \
            --prefix="$TARGET_DIR" \
            --libdir="$TARGET_DIR/lib" \
            --extra-cflags="-I$TARGET_DIR/include" \
            --extra-ldflags="-L$TARGET_DIR/lib" \
            --extra-ldexeflags="-static" \
            --pkg-config-flags="--static" --disable-shared --enable-static \
            --enable-nonfree \
            --enable-libfdk-aac
    else
        ./configure --prefix="$TARGET_DIR" \
            --extra-cflags="-I$TARGET_DIR/include" \
            --extra-ldflags="-L$TARGET_DIR/lib" \
            --extra-ldexeflags="-static" \
            --pkg-config-flags="--static" --disable-shared --enable-static \
            --enable-libmp3lame \
            --enable-nonfree \
            --enable-libopus \
            --enable-libfdk-aac
    fi

    echo "Build"
    nice -n 20 make -j $THREADS
    echo "Install"
    make install || echo
)
if [[ -f "$TARGET_DIR/bin/ffmpeg" ]]; then
    echo "Copying ffmpeg to Docker"
    if [[ $CCPREFIX ]]; then
        cp -f "$TARGET_DIR/bin/ffmpeg" ../"$DOCKER_FFMPEG""_arm"
    else
        cp -f "$TARGET_DIR/bin/ffmpeg" ../"$DOCKER_FFMPEG"
    fi
fi

