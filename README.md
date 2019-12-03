# LHLSWifiTranslation
LHLS Simultaneous translation engine using HTML5, hls.js and ffmpeg

Provides simultanious translation audio via a low-latency web player for smart phone web browsers.

# To build

## Download hls.js

This can be obtained from https://github.com/video-dev/hls.js/. This is copied locally since a WiFi for translation may or may not have external Internet access and therefore our web player can't have external dependencies.

```
wget "https://cdn.jsdelivr.net/npm/hls.js@canary" -O lhls_web_server/root/var/www/html/lhls/js/hls.js
```

## Compile FFmpeg

This compiles a static version of FFmpeg with FDK-AAC that has the AAC_HE profile for high quality speech at low bandwidths

```
cd ffmpeg
./ffmpeg-static-builder.sh
```

## Build the Dockers

docker-compose build

# To use

## Start the Dockers
docker-compose up

## Send an audio source to the LHLS transcoder

The transcoders listen for RTP packets as input since this is the most practical way I could think of to get audio into the Docker.

This can be done with any version of ffmpeg. Sending 16 bit uncompressed PCM is a good way to get the audio to the transcoder without loss or latency.

Here are some examples:

### Windows
First get a list of audio device names
```
ffmpeg.exe -list_devices true -f dshow -i dummy
```
Assuming we have an input device called, "Microphone (High Definition Aud" then we could use the following command to activate the transcoder.
```
ffmpeg.exe -f dshow -ac 1 -ar 44100 -i audio="Microphone (High Definition Aud" -fflags nobuffer -flags low_delay -c:a pcm_s16be -ar 44100 -f rtp rtp://127.0.0.1:10000
```

The languages are selected by port numbers. We add 2 to the base port number to get the next language. For example, this would give us the "French" channel using the default docker-compose file.
```
ffmpeg.exe -f dshow -ac 1 -ar 44100 -i audio="Microphone (High Definition Aud" -fflags nobuffer -flags low_delay -c:a pcm_s16be -ar 44100 -f rtp rtp://127.0.0.1:10002
```

### Linux
This is an example of a Linux audio source. In this case we would get the "Spanish" channel.
```
ffmpeg -f alsa -ac 1 -ar 44100 -i plughw:1 -fflags nobuffer -flags low_delay -c:a pcm_s16be -ar 44100 -f rtp rtp://192.168.210.90:10004
```

# To customise

The most common settings are in the docker-compose.yml file.

 Currently the web server is exposed on port 8080. This could easily be changed to port 80 by changing `"8080:80/tcp"` to `"80:80/tcp"`.

 The LANGUAGES environment variable selects the list of language channel names in order of portnumber * 2 from the base port.

 There are more environment variables that can be set in docker-compose.yml, see the individual Dockerfiles for details.