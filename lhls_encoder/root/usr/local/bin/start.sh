#!/bin/ash
TIMEOUT=20
TMPDIR="/dev/shm"
DUMP_FILE="$TMPDIR/dump.txt"
PORTS_FILE="$TMPDIR/ports.txt"
STREAMS_FILE="$TMPDIR/streams.txt"
TRANSCODERS_FILE="$TMPDIR/transcoders.txt"
PORTS_ENABLE_FILE="$TMPDIR/ports.run"
if arch | grep -qiF "arm"; then
    FFMPEG="/usr/local/bin/ffmpeg_arm"
else
    FFMPEG="/usr/local/bin/ffmpeg"
fi
TRANSLOCKDIR="$TMPDIR/translock"

endtime=$(( $( date "+%s" ) + TIMEOUT ))

cleanup () {
    trap - INT TERM
    
    rm -f "$PORTS_ENABLE_FILE"
    if ps aux | grep -v grep | grep -q "$FFMPEG"; then
        kill -KILL $( ps aux | grep -v grep | grep "$FFMPEG" | awk '{print $2}' )
    fi
    exit
}

transcode_register () {
    local port=$1 action=$2 i

    # Wait up to 10 seconds for lock
    for i in 0 1 2 3 4 5 6 7 8 9; do
        if mkdir "$TRANSLOCKDIR" 2>/dev/null; then
            break
        fi
        sleep 1
    done
    # Add or subtract port from transcoder register
    case "$action" in
        add)
            touch "$TRANSCODERS_FILE"
            grep -v "$port" "$TRANSCODERS_FILE" | sort | uniq > "$TRANSCODERS_FILE""_new"
            echo "$port" >> "$TRANSCODERS_FILE""_new"
            mv -f "$TRANSCODERS_FILE""_new" "$TRANSCODERS_FILE"    
            ;;
        remove)
            grep -v "$port" "$TRANSCODERS_FILE" | sort | uniq > "$TRANSCODERS_FILE""_new"
            mv -f "$TRANSCODERS_FILE""_new" "$TRANSCODERS_FILE"
            ;;
    esac
    rmdir "$TRANSLOCKDIR"
}


# Throw up a transcoder
transcode () {
    local port=$1 webserver_ip=$2 first_transcode=$3 lang_index=$(( ( ( port - BASE_PORT ) / 2 ) + 1 )) lang
    
    lang=$( echo "$LANGUAGES" | tr ", " "\t" | cut -f $lang_index )
    
    if [[ ${#lang} -lt 1 ]]; then
        echo "Language for port $port not defined" >&2
        return
    fi
    
    transcode_register "$port" "add"
    while [[ -f "$PORTS_ENABLE_FILE" ]] && grep -qF $port "$PORTS_FILE"; do
        if [[ "$first_transcode" == "yes" ]]; then
            echo
            echo ">>> ffmpeg transcode check"
            echo "$FFMPEG -i rtp://0.0.0.0:$port $CODEC_PARAMS $CHUNK_PARAMS \"http://$webserver_ip/$LHLS_PATH/$lang/$MANIFEST_FILE\" 2>&1"
            timeout 2 $FFMPEG -i rtp://0.0.0.0:$port $CODEC_PARAMS $CHUNK_PARAMS "http://$webserver_ip/$LHLS_PATH/$lang/$MANIFEST_FILE" 2>&1
            echo ">>> ffmpeg transcode check complete"
            echo
        fi
        echo "Starting $lang from port $port"
        $FFMPEG -i rtp://0.0.0.0:$port $CODEC_PARAMS $CHUNK_PARAMS "http://$webserver_ip/$LHLS_PATH/$lang/$MANIFEST_FILE" >/dev/null 2>&1
        echo "ffmpeg ended for $lang from port $port"
        sleep 1
    done
    transcode_register "$port" "remove"
    echo "Stopped $lang from port $port"
}

# Report incoming UDP packets over 2 second windows
port_scanner () {
    local netp=$1 ports
    while [[ -f "$PORTS_ENABLE_FILE" ]]; do
        timeout 2 tcpdump -i "$netp" -n udp >"$DUMP_FILE" 2>/dev/null
        ports=$( grep -Eo "[0-9]+:[[:space:]]*UDP" "$DUMP_FILE" | grep -Eo "^[0-9]+" | grep -E "[02468]$" | sort | uniq )
        echo "$ports" >"$PORTS_FILE""_new"
        mv -f "$PORTS_FILE""_new" "$PORTS_FILE"
        sleep 2
    done
}

# Report any RTP streams that will play
stream_scanner () {
    local port stream webserver_ip=$1 first_test="yes" first_transcode="yes"
    while [[ -f "$PORTS_ENABLE_FILE" ]]; do
        if [[ -f "$PORTS_FILE" ]]; then 
            for port in $( cat "$PORTS_FILE" ); do
                [[ -f "$PORTS_ENABLE_FILE" ]] || break
                # Already an encoder running
                if [[ -f "$TRANSCODERS_FILE" ]] && grep -q "$port" "$TRANSCODERS_FILE"; then
                    echo "$port" >> "$STREAMS_FILE""_new"
                else
                    # Test if packets are viable audio stream
                    # For first time show what ffmpeg is seeing for debugging purposes
                    if [[ "$first_test" == "yes" ]]; then
                        echo
                        echo ">>> ffmpeg stream test check"
                        echo "$FFMPEG -y -i rtp://0.0.0.0:$port -progress -vn -c:a copy -f nut /dev/null"
                        timeout 2 $FFMPEG -y -i rtp://0.0.0.0:$port -progress -vn -c:a copy -f nut /dev/null 2>&1
                        first_test="no"
                        echo ">>> ffmpeg stream test check complete"
                        echo
                    fi
                    stream=$( timeout 2 $FFMPEG -y -i rtp://0.0.0.0:$port -progress -vn -c:a copy -f nut /dev/null 2>&1 | grep -Ei "Stream.*Audio:" | grep -Ei "mono|stereo" | head -n 1 )
                    if [[ ${#stream} -gt 1 ]]; then
                        echo "$port" >> "$STREAMS_FILE""_new"
                        transcode "$port" "$webserver_ip" "$first_transcode" &
                        first_transcode="no"
                    else
                        echo "UDP packets on port $port didn't result in ffmpeg test output with words \"Stream\" and \"Audio:\" in same line that would indicate an audio stream" >&2
                    fi
                fi
            done
        fi
        sleep 2        
        if [[ -f "$STREAMS_FILE""_new" ]]; then
            mv -f "$STREAMS_FILE""_new" "$STREAMS_FILE"
        else
            echo >"$STREAMS_FILE"
        fi
    done
}

# Wait for nic
while [[ $( date "+%s" ) -lt $endtime ]]; do
    netp=$( ip link show | grep -Eo "^[0-9]+:[[:space:]]*[^:@]+" | grep -v "lo" | tail -n 1 | grep -Eo "[^[:space:]]+$" )
    [[ ${#netp} -gt 1 ]] && break
    sleep 1
done
if [[ $( date "+%s" ) -ge $endtime ]]; then
    echo "Timeout waiting for local nic" >&2
    exit 1
fi

# Wait for environment variable web server address to come alive
while [[ $( date "+%s" ) -lt $endtime ]]; do
    wget -T 1 -q -O /dev/null "http://$WEBSERVER" && break
    sleep 1
done
if [[ $( date "+%s" ) -ge $endtime ]]; then
    echo "Timeout waiting for web server at $WEBSERVER" >&2
    exit 1
fi
webserver_ip=$( nslookup lhls_web_server 2>/dev/null | grep "Address" | grep -Eo "([0-9]{1,3}\.){3}[0-9]{1,3}" )

echo "Nic is $netp, Webserver ip is $webserver_ip"

touch "$PORTS_ENABLE_FILE"
trap cleanup INT TERM

port_scanner "$netp" &
stream_scanner "$webserver_ip" &
while [[ -f "$PORTS_ENABLE_FILE" ]]; do
    sleep 2
done

