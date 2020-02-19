var gStatus = {};
var gStatusUpdate = false;
var gJsonpTimeout = 1000;

var gPlayIntention = false;
var gPlaying = false;
var gLang = window.navigator.language.substring(0,2);

/* var m3uObj = {
    content = "",
    seq = 0,
    digits = 0,
    chunkLength = 0.0,
    firstChunkDate = new Date(),
    dateOfCapture = new Date()
    
} */

/*
Possible parameters to reduce latency
        maxMaxBufferLength: 1,
        liveSyncDuration: 0.5,
        liveMaxLatencyDuration: 1,
        liveBackBufferLength: 0,
*/

if(Hls.isSupported()) {
    // Low latency recepe
    var config = {
        nudgeMaxRetry: 100,
        debug: false
    };    
    var hls = new Hls(config);
}
window.onload = function () {
    var audio = document.getElementById('audio');
    var video = document.getElementById('video');
    if (!localStorage.channel) {
        localStorage.channel = "english";
    }
    
    if(Hls.isSupported()) {
        hls.loadSource("audio/" + localStorage.channel + "/media_0.m3u8");
        hls.attachMedia(audio);

        audio.onplay = function() {
            // Jump to most recent possible position
            if (hls.liveSyncPosition > 0) {
                audio.currentTime = hls.liveSyncPosition;
            }
        };
    } else if (audio.canPlayType('application/vnd.apple.mpegurl')) {
        // If we get here then things will fall back to standard HLS
        audio.src = 'hls/out.m3u8';
        audio.addEventListener('loadedmetadata',function() {
        });
    }    
    pollStatus();
    setInterval(pollStatus, 5000);    
};

//Poll status every two seconds
function pollStatus () {
    loadJSONP(
        "channels.php",
        function(newStatus) {
            if (JSON.stringify(gStatus) !== JSON.stringify(newStatus)) {
                console.log(newStatus);
                gStatus = newStatus;
                gStatusUpdate = true;
                updateDisplay();
                /* if (!checkStreamOK) {
                    stopPlay();
                    //updateDisplay();
                } */
            }
        }, null, null, "jpstat"
    );
}

function channelNameLookup (channel) {
    var name = (parseInt(channel) + 1).toString();
    if ((channel < gStatus.length) && (gStatus[channel].hasOwnProperty("name"))) {
        name = gStatus[channel]["name"];
    }
    return name;
}

function channelNumberLookup (name) {
    for (var channel in gStatus) {
        if (gStatus[channel].hasOwnProperty("name")) {
            name = gStatus[channel]["name"];
            return channel;
        }        
    }
}

function updateDisplay() {
    var listHtml = '';
    for (var channel in gStatus) {

        var status = false;
        var name = (parseInt(channel) + 1).toString();
        
        if (gStatus[channel].hasOwnProperty('valid')) {
            status = gStatus[channel]['valid'];
        }
        if (gStatus[channel].hasOwnProperty("name")) {
            name = gStatus[channel]["name"];
        }
         
        if (status) {
            listHtml += "<a href=\"#\"" +
            " onclick=\"onclickChannel(" + channel + ");\"" +
            " ontouchend=\"ontouchendChannel(" + channel + ");\"" +
            ">" + name + "</a>\n";
        } else {
            listHtml += "<a href=\"#\" class=\"disabled\">" + name + "</a>\n";
        }

        if (name == localStorage.channel) {
            var chNameId = document.getElementById("chName");
            var startStopButtonId = document.getElementById("startStopButton");
            chNameId.innerHTML = name;
            if (status) {
                if (chNameId.classList.contains('chNameDead')) {
                    chNameId.classList.remove('chNameDead');
                }
                startStopButtonId.innerText = LANG[gLang][(gPlayIntention)?"stop":"start"];
                // Reload and start audio
                if (gPlayIntention) {
                    loadAudio();
                    audio.play();
                }
                startStopButtonId.disabled = false;
            } else {
                if (!chNameId.classList.contains('chNameDead')) {
                    chNameId.classList.add('chNameDead');
                }
                startStopButtonId.innerText = LANG[gLang][(gPlayIntention)?"stop":"start"];
                startStopButtonId.disabled = !gPlayIntention;
            }
        }
    }
    var element = document.getElementById("chSelectList");
    element.innerHTML = listHtml;
    document.getElementById('chSelectBtn').innerText = LANG[gLang]["select"];
    document.getElementById('stat').innerText = "";
    var vidDivId = document.getElementById("vid");
    if (vidDivId) {
        if (gPlaying) {
            if (vidDivId.classList.contains('vidStopped')) {
                vidDivId.classList.remove('vidStopped');
                vidDivId.classList.add('vidStarted');
            }
        } else {
            if (vidDivId.classList.contains('vidStarted')) {
                vidDivId.classList.remove('vidStarted');
                vidDivId.classList.add('vidStopped');
            }
        }
    }
}

//Drop down menu related
function chSelect() {
    document.getElementById("chSelectList").classList.toggle("show");
}
// Close the dropdown menu if the user clicks outside of it
window.onclick = function(event) {
  if (!event.target.matches('.dropbtn')) {

    var dropdowns = document.getElementsByClassName("dropdown-content");
    var i;
    for (i = 0; i < dropdowns.length; i++) {
      var openDropdown = dropdowns[i];
      if (openDropdown.classList.contains('show')) {
        openDropdown.classList.remove('show');
      }
    }
  }
  //Hide QR code if showing
  if (!event.target.matches('.qrBtn')) {
    var boxDiv = document.getElementById("qrBox");
    if (boxDiv.classList.contains("qrShow")) {
        boxDiv.classList.remove("qrShow");
    }
  }
}


function loadAudio () {
    if(Hls.isSupported()) {
        // Reload the source to reset the buffer
        hls.loadSource("audio/" + localStorage.channel + "/media_0.m3u8");
        hls.attachMedia(audio);
    }    
}

function startPlay() {
    //loadAudio();
    //audio.play();
    var vidPlayer = document.getElementById('playing');
    if (vidPlayer) {
        vidPlayer.play();
    }
    gPlaying = true;
    updateDisplay();
}
function stopPlay() {
    audio.pause();
    var vidPlayer = document.getElementById('playing');
    if (vidPlayer) {
        vidPlayer.pause();
    }
    gPlaying = false;
    updateDisplay();
}

function onclickStart() {
    if (!mobileAndTabletcheck()) {
        startPlay();
    }
}
function ontouchendStart() {
    if (mobileAndTabletcheck()) {
        startPlay();
    }    
}
function onclickChannel(channel) {
    if (!mobileAndTabletcheck()) {
        localStorage.channel = channelNameLookup(channel);
        updateDisplay();
        if (gPlaying) {
            console.log("Stop on channel change");
            stopPlay();
            startPlay();
        }
    }
}
function ontouchendChannel(channel) {
    if (mobileAndTabletcheck()) {
        localStorage.channel = channelNameLookup(channel);
        updateDisplay();
        if (gPlaying) {
            startPlay();
        }
    }
}

// The main start/stop button handler
function clickEnact() {
    //Check if retry pressed
    var startStopButtonId = document.getElementById("startStopButton");
    if (startStopButtonId.innerText == LANG[gLang]["retry"]) {
        location.reload(true);
    }
    if (gPlayIntention) {
        gPlayIntention = false;
        /* if (mobileAndTabletcheck()) {
            closeFullscreen();
        } */
        console.log("Stop on clickEnact");
        stopPlay();
    } else {
        gPlayIntention = true;
        console.log("Start on clickEnact");
        startPlay();
    }
}

function startStopPlayerClick() {
    if (!mobileAndTabletcheck()) {
        clickEnact();
    }
}

function startStopPlayerTouchend() {
    if (mobileAndTabletcheck()) {
        clickEnact();
    }
}
