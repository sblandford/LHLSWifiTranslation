<?php
/*

ffmpeg-static -f alsa -ac 2 -ar 44100 -i hw:1,0 -fflags nobuffer -flags low_delay -vn -c:a libfdk_aac -profile:a aac_he -ar 44100 -ac 1 -b:a 16k -bsf:a aac_adtstoasc -window_size 2 -hls_playlist 1 -seg_duration 0.5 -streaming 1 -strict experimental -lhls 1 -remove_at_exit 0 -master_m3u8_publish_rate 1  -f dash -method PUT -http_persistent 0  "http://127.0.0.1/audio/manifest.mpd"

ffmpeg-static -re -f lavfi -i "sine=frequency=1000" -c:a pcms16le -vn -c:a libfdk_aac -profile:a aac_he -ar 44100 -ac 1 -b:a 16k -bsf:a aac_adtstoasc -window_size 2 -hls_playlist 1 -seg_duration 0.5 -streaming 1 -strict experimental -lhls 1 -remove_at_exit 0 -master_m3u8_publish_rate 1  -f dash -method PUT -http_persistent 0  "http://127.0.0.1/audio/manifest.mpd"

*/

define ("HLS_MANIFEST_DIR", "data");

function getUserIpAddr(){
    if(!empty($_SERVER['HTTP_CLIENT_IP'])){
        //ip from share internet
        $ip = $_SERVER['HTTP_CLIENT_IP'];
    }elseif(!empty($_SERVER['HTTP_X_FORWARDED_FOR'])){
        //ip pass from proxy
        $ip = $_SERVER['HTTP_X_FORWARDED_FOR'];
    }else{
        $ip = $_SERVER['REMOTE_ADDR'];
    }
    return $ip;
}


if ( substr(getUserIpAddr(),0,8) !== "192.168." && 
        substr(getUserIpAddr(),0,4) !== "172." &&
        substr(getUserIpAddr(),0,5) !== "10.0." &&
        substr(getUserIpAddr(),0,8) !== "127.0.0." ) {
    http_response_code (403);
    throw new Exception("Only data LAN may access this, not " . getUserIpAddr());
}

if (strpos(__DIR__, dirname($_SERVER['REQUEST_URI'])) !== false) {
    throw new Exception("No channel name found in URI\n");
}

// Get channel name if we have one
$channel = basename(dirname($_SERVER['REQUEST_URI']));
@mkdir(HLS_MANIFEST_DIR . "/" . $channel);

$filename = HLS_MANIFEST_DIR . "/" . $channel . "/" . basename($_SERVER['REQUEST_URI']);

switch ($_SERVER['REQUEST_METHOD']) {
    case "PUT":
        session_start();
        $putdata = fopen("php://input", "r");

        /* Open a file for writing */
        $fp = fopen($filename, "w");

        /* Read the data 1 KB at a time
        and write to the file */
        while ($data = fread($putdata, 1024)) {
            fwrite($fp, $data);
        }

        /* Close the streams */
        fclose($fp);
        fclose($putdata);
        break;
    case "DELETE":
        @unlink($filename);
        break;
    default:
        throw new Exception("Unsupported method : " . $_SERVER['REQUEST_METHOD']);
        break;
}
?>
 
