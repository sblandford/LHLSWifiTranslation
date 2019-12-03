FROM alpine:latest

MAINTAINER Simon Blandord <simon@bkconnect.net>

COPY root/. /

ENV WEBSERVER localhost
ENV CODEC_PARAMS -c:a libfdk_aac -profile:a aac_he -ar 44100 -ac 1 -b:a 24k -bsf:a aac_adtstoasc
ENV CHUNK_PARAMS -window_size 2 -extra_window_size 4 -hls_playlist 1 -seg_duration 0.5  -streaming 1 -strict experimental -lhls 1 -remove_at_exit 1 -master_m3u8_publish_rate 1 -f dash -method PUT -http_persistent 1 -ignore_io_errors 1
ENV LANGUAGES English,French,Spanish,Tamil,Russian,Portugese
ENV LHLS_PATH lhls/audio
ENV MANIFEST_FILE manifest.mpd
ENV BASE_PORT 10000

RUN apk update && apk upgrade && \
    # Install tcpdump
    apk add tcpdump && \
    chmod +x -R /usr/local/bin
    
# Input port range
EXPOSE 10000-10020/udp

# Define default command.
CMD ["/usr/local/bin/start.sh"]
