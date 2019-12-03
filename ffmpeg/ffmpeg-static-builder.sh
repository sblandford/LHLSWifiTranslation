#!/bin/bash
# Build static FFMPEG with ALSA and FDK AAC support

set -e
TARGET_DIR="$( pwd )/static_build"
DOCKER_FFMPEG="lhls_encoder/root/usr/local/bin/ffmpeg"
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
        ./configure --prefix="$TARGET_DIR" --enable-static=yes --enable-shared=no
        echo "Alsa build"
        nice -n 20 make -j 8
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
        ./autogen.sh
        ./configure --prefix="$TARGET_DIR" --disable-shared
        echo "FDK AAC compile"
        nice -n 20 make -j 8
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

    ./configure --prefix="$TARGET_DIR" \
        --extra-cflags="-I$TARGET_DIR/include" \
        --extra-ldflags="-L$TARGET_DIR/lib" \
        --extra-ldexeflags="-static" \
        --pkg-config-flags="--static" --disable-shared --enable-static \
        --enable-libmp3lame \
        --enable-nonfree \
        --enable-libopus \
        --enable-libfdk-aac

    echo "Build"
    nice -n 20 make -j 8
    echo "Install"
    make install || echo
)
if [[ -f "$TARGET_DIR/bin/ffmpeg" ]]; then
    echo "Copying ffmpeg to Docker"
    cp -f "$TARGET_DIR/bin/ffmpeg" ../"$DOCKER_FFMPEG"
fi

