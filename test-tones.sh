#!/bin/bash

cleanup () {
    trap - INT TERM
    
    rm -f "$PORTS_ENABLE_FILE"
    if ps aux | grep -v grep | grep ffmpeg | grep -q pcm_s16be; then
        kill -KILL $( ps aux | grep -v grep | grep ffmpeg | grep -q pcm_s16be | awk '{print $2}' )
    fi
    sleep 1
    echo
    echo
    exit
}

for (( i=0; i<20; i+=2 )); do
    freq=$(( 432 + (i * 10) ))
    ffmpeg -re -f lavfi -i "sine=frequency=$freq" -c:a pcm_s16be -ar 44100 -f rtp rtp://localhost:$(( 10000 + i )) &
done

while [ 1 ]; do
    sleep 1
done

