<?php

$protocol=$_SERVER['PROTOCOL'] = isset($_SERVER['HTTPS']) && !empty($_SERVER['HTTPS']) ? 'https' : 'http';
$host = $_SERVER['SERVER_ADDR'];
$port = "";
$path = dirname($_SERVER['REQUEST_URI']);
if ($path === "/") $path = "";

if (($_SERVER['SERVER_PORT'] !== "80") && ($_SERVER['SERVER_PORT'] !== "443")) $port = ":" . $_SERVER['SERVER_PORT'];
if (array_key_exists('HTTP_X_FORWARDED_FOR', $_SERVER)) $host = $_SERVER['HTTP_X_FORWARDED_FOR'];

if ($host === "::1") $host = "127.0.0.1";
// Extract IPv4
$ip4matches = array ();
preg_match('/([0-9]{1,3}\.){3}[0-9]{1,3}/', $host, $matches);
if (count($matches) > 0) $host = $matches[0];

// Prefer hostname if set
if (array_key_exists('HTTP_HOST', $_SERVER) && ($_SERVER['HTTP_HOST'] !== "localhost")) $host = $_SERVER['HTTP_HOST'];
//If the host cotains the port number then don't repeat it
if (strpos($host, ":") !== false) {
    $port="";
}

?>
<!DOCTYPE html>
<html>
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1" >
        <title>Translation QR code</title>
        <script src="js/qrcode.js"></script>
    </head>
    <body>
        <div style="display: flex;align-items: center;justify-content: center">
            <table>
                <tr><td><div><h1 style="font-size: 1.2em;"><?php echo "$protocol://$host$port$path" ?></h1></div></tr></td>
                <tr><td><div id="qrcode"></div></tr></td>
            </table>
        </div>
        <script type="text/javascript">
            new QRCode(document.getElementById("qrcode"), "<?php echo "$protocol://$host$port$path" ?>");
        </script>
    </body>
</html>
