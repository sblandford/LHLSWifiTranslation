<?php
    function isMobileDevice(){
        $aMobileUA = array(
            '/iphone/i' => 'iPhone', 
            '/ipod/i' => 'iPod', 
            '/ipad/i' => 'iPad', 
            '/android/i' => 'Android', 
            '/blackberry/i' => 'BlackBerry', 
            '/webos/i' => 'Mobile'
        );

        //Return true if Mobile User Agent is detected
        foreach($aMobileUA as $sMobileKey => $sMobileOS){
            if(preg_match($sMobileKey, $_SERVER['HTTP_USER_AGENT'])){
                return true;
            }
        }
        //Otherwise return false..  
        return false;
    }

    $mobile = isMobileDevice();
?>
<!DOCTYPE html>
<html>
   <head>
      <title>LHLS server</title>
      <meta http-equiv = "refresh" content = "0; url = /lhls/<?php echo ($mobile)?"index.html":"desktop.html";?>" />
   </head>
   <body>
   </body>
</html> 
