<?php
define ("HLS_MANIFEST_DIR", "audio/data");
define ("MAX_AGE_LIST_SECONDS", 60 * 60 * 24);
define ("MAX_AGE_LIVE_SECONDS", 10);
define ("CACHE_SECONDS", 5);
define ("CACHE_FILE", "/channels.cache");

// Use cache if fresh enough. The HLS_MANIFEST_DIR should be a tmpfs mount for performance.
$cache = HLS_MANIFEST_DIR . CACHE_FILE;
if (file_exists($cache) && ((time() - filemtime($cache)) < CACHE_SECONDS)) {
    die ($_GET['callback'] . "(" . file_get_contents($cache) . ")");
}

$dirs = scandir (HLS_MANIFEST_DIR);
sort($dirs);

function delTree($dir) {
    $files = array_diff(scandir($dir), array('.','..'));
    foreach ($files as $file) {
        (is_dir("$dir/$file") && !is_link($dir)) ? delTree("$dir/$file") : unlink("$dir/$file");
    }
    return rmdir($dir);
}

$channels = array();

foreach ($dirs as $channel) {
    if ($channel === "." || $channel === ".." ) continue;
    $dir = HLS_MANIFEST_DIR . "/" . $channel;
    if (!is_dir($dir)) continue;

    // Find newest file in channel or channel dir itself
    $newest = $dir;
    $files = scandir($dir, SCANDIR_SORT_DESCENDING);

    if (count($files) > 0) {
        $newest = $dir . "/" . $files[0];
    }
    
    // Remove from listing if really old
    $newest_age = time() - filemtime($newest);
    if ($newest_age > MAX_AGE_LIST_SECONDS) {
        delTree($dir);
        continue;
    }
    $valid = false;
    if ($newest_age < MAX_AGE_LIVE_SECONDS) {
        $valid = true;
    }
    $channels[] = (object) array ('name'  => $channel, 'valid' => $valid);
}

$channels_json = json_encode ($channels);

file_put_contents($cache, $channels_json);

die($_GET['callback'] . "( " . $channels_json . ") ");
?>
