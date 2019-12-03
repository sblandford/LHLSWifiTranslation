//Based on JSONP loader by Gianni Chiappetta
//https://gist.github.com/gf3/132080
var loadJSONP = (function(){
    var unique = 0;
    return function(url, callback, errCallback, context, callbackName) {
    // INIT
    var name = "jp" + unique++;
    if (callbackName) {
        name = callbackName;
    }
    if (url.match(/\?/)) {
        url += "&callback="+name;
    } else {
        url += "?callback="+name;
    }
    
    // Create script
    var script = document.createElement('script');
    script.type = 'text/javascript';
    script.src = url;
    
    // Setup handler
    window[name] = function(data){
        callback.call((context || window), data);
        document.getElementsByTagName('head')[0].removeChild(script);
        script = null;
        delete window[name];
    };
    
    // Timeout (assume error)
    setTimeout(function () {
        expireJSONP(name, script, errCallback, context);
    }, gJsonpTimeout);
    
    // Load JSON
    document.getElementsByTagName('head')[0].appendChild(script);
  };
})();
function expireJSONP (name, script, errCallback, context) {
    //If handler hasn't triggered then callback will still exist
    if (window.hasOwnProperty(name)) {
        if (errCallback) {
            errCallback.call((context || window));
        }
        //Clean up
        try {
            document.getElementsByTagName('head')[0].removeChild(script);
        } catch (err) {
            ;//Pass
        }
        script = null;
        delete window[name];
    }
}

function showQr() {
    var boxWidth, boxHeight;
    var boxDiv = document.getElementById("qrBox");
    var boxObj = document.getElementById("qrObj");
    
    //Needs two iterations to settle on correct size
    for (var i=0; i < 2; i++) {
        boxWidth = boxDiv.offsetWidth;
        boxHeight = boxDiv.offsetHeight;
        
        boxObj.width = document.documentElement.clientWidth;
        boxObj.height = document.documentElement.clientHeight * 0.6;
        
        if (boxWidth < 400) {
            scale = boxWidth / 400;
            boxObj.style.transform = "scale(" + scale + ")";
        } else {
            boxObj.style.transform = "scale(1)";
        }
    }
    boxDiv.classList.toggle("qrShow");
}

var mobileAndTabletState = null;
function mobileAndTabletcheck () {
    
    if (mobileAndTabletState == null) {
        mobileAndTabletState = false;
        
        (function(a){if(/(android|bb\d+|meego).+mobile|avantgo|bada\/|blackberry|blazer|compal|elaine|fennec|hiptop|iemobile|ip(hone|od)|iris|kindle|lge |maemo|midp|mmp|mobile.+firefox|netfront|opera m(ob|in)i|palm( os)?|phone|p(ixi|re)\/|plucker|pocket|psp|series(4|6)0|symbian|treo|up\.(browser|link)|vodafone|wap|windows ce|xda|xiino|android|ipad|playbook|silk/i.test(a)||/1207|6310|6590|3gso|4thp|50[1-6]i|770s|802s|a wa|abac|ac(er|oo|s-)|ai(ko|rn)|al(av|ca|co)|amoi|an(ex|ny|yw)|aptu|ar(ch|go)|as(te|us)|attw|au(di|-m|r |s )|avan|be(ck|ll|nq)|bi(lb|rd)|bl(ac|az)|br(e|v)w|bumb|bw-(n|u)|c55\/|capi|ccwa|cdm-|cell|chtm|cldc|cmd-|co(mp|nd)|craw|da(it|ll|ng)|dbte|dc-s|devi|dica|dmob|do(c|p)o|ds(12|-d)|el(49|ai)|em(l2|ul)|er(ic|k0)|esl8|ez([4-7]0|os|wa|ze)|fetc|fly(-|_)|g1 u|g560|gene|gf-5|g-mo|go(\.w|od)|gr(ad|un)|haie|hcit|hd-(m|p|t)|hei-|hi(pt|ta)|hp( i|ip)|hs-c|ht(c(-| |_|a|g|p|s|t)|tp)|hu(aw|tc)|i-(20|go|ma)|i230|iac( |-|\/)|ibro|idea|ig01|ikom|im1k|inno|ipaq|iris|ja(t|v)a|jbro|jemu|jigs|kddi|keji|kgt( |\/)|klon|kpt |kwc-|kyo(c|k)|le(no|xi)|lg( g|\/(k|l|u)|50|54|-[a-w])|libw|lynx|m1-w|m3ga|m50\/|ma(te|ui|xo)|mc(01|21|ca)|m-cr|me(rc|ri)|mi(o8|oa|ts)|mmef|mo(01|02|bi|de|do|t(-| |o|v)|zz)|mt(50|p1|v )|mwbp|mywa|n10[0-2]|n20[2-3]|n30(0|2)|n50(0|2|5)|n7(0(0|1)|10)|ne((c|m)-|on|tf|wf|wg|wt)|nok(6|i)|nzph|o2im|op(ti|wv)|oran|owg1|p800|pan(a|d|t)|pdxg|pg(13|-([1-8]|c))|phil|pire|pl(ay|uc)|pn-2|po(ck|rt|se)|prox|psio|pt-g|qa-a|qc(07|12|21|32|60|-[2-7]|i-)|qtek|r380|r600|raks|rim9|ro(ve|zo)|s55\/|sa(ge|ma|mm|ms|ny|va)|sc(01|h-|oo|p-)|sdk\/|se(c(-|0|1)|47|mc|nd|ri)|sgh-|shar|sie(-|m)|sk-0|sl(45|id)|sm(al|ar|b3|it|t5)|so(ft|ny)|sp(01|h-|v-|v )|sy(01|mb)|t2(18|50)|t6(00|10|18)|ta(gt|lk)|tcl-|tdg-|tel(i|m)|tim-|t-mo|to(pl|sh)|ts(70|m-|m3|m5)|tx-9|up(\.b|g1|si)|utst|v400|v750|veri|vi(rg|te)|vk(40|5[0-3]|-v)|vm40|voda|vulc|vx(52|53|60|61|70|80|81|83|85|98)|w3c(-| )|webc|whit|wi(g |nc|nw)|wmlb|wonu|x700|yas-|your|zeto|zte-/i.test(a.substr(0,4))) mobileAndTabletState = true;})(navigator.userAgent||navigator.vendor||window.opera);
    }
    return mobileAndTabletState;
}

// https://stackoverflow.com/questions/4907843/open-a-url-in-a-new-tab-and-not-a-new-window-using-javascript
function openInNewTab(url) {
    var a = document.createElement("a");
    a.target = "_blank";
    a.href = url;
    a.click();
}


// https://www.w3schools.com/howto/howto_js_fullscreen.asp
/* Get the documentElement (<html>) to display the page in fullscreen */
/* View in fullscreen */
function openFullscreen() {
    var elem = document.documentElement;

    if (elem.requestFullscreen) {
        elem.requestFullscreen();
    } else if (elem.mozRequestFullScreen) { /* Firefox */
        elem.mozRequestFullScreen();
    } else if (elem.webkitRequestFullscreen) { /* Chrome, Safari and Opera */
        elem.webkitRequestFullscreen();
    } else if (elem.msRequestFullscreen) { /* IE/Edge */
        elem.msRequestFullscreen();
    }
}

/* Close fullscreen */
function closeFullscreen() {
    var elem = document.documentElement;
    
    if (document.exitFullscreen) {
        document.exitFullscreen();
    } else if (document.mozCancelFullScreen) { /* Firefox */
        document.mozCancelFullScreen();
    } else if (document.webkitExitFullscreen) { /* Chrome, Safari and Opera */
        document.webkitExitFullscreen();
    } else if (document.msExitFullscreen) { /* IE/Edge */
        document.msExitFullscreen();
    }
}

