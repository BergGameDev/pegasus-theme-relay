import QtQuick 2.5

FocusScope {
    id: splash
    objectName: "relayStartupSplash"
    property var owner
    property bool started: false
    property bool closing: false
    property int heldKey: -1
    property real elapsed: 0
    property bool quiet: false
    signal finished()
    focus: true
    function begin() {
        if(started || closing) return;
        started=true;
        quiet=owner.preferences.reducedMotion || !owner.preferences.animation;
        if(quiet) elapsed=1850; else sequence.start();
        if(!owner.preferences.splashWait && heldKey===-1) { automatic.interval=quiet ? 650:1850;automatic.start(); }
        forceActiveFocus();
    }
    function dismiss() {
        if(closing) return;
        closing=true;automatic.stop();sequence.stop();
        exitFade.duration=quiet ? 0:180;exitFade.start();
    }
    function progress(start,duration) { return Math.max(0,Math.min(1,(elapsed-start)/duration)); }
    Rectangle { anchors.fill:parent;color:"#171c1c" }
    FontLoader {id:brandFont;source:"../assets/fonts/ShareTech-Regular.ttf"}
    Item {
        width:1920;height:1080;anchors.centerIn:parent
        scale:Math.min(splash.width/width,splash.height/height)
        visible:splash.started
        Text {
            anchors.horizontalCenter:parent.horizontalCenter;y:378
            text:"RELAY";color:"#f1f4f2";font.family:brandFont.name
            font.pixelSize:152;font.letterSpacing:19
            opacity:splash.progress(0,250)
        }
        Row {
            anchors.horizontalCenter:parent.horizontalCenter;y:531;spacing:27
            Item {
                width:84;height:80
                Item {
                    width:84*splash.progress(0,450);height:80;clip:true
                    Image {
                        width:84;height:80;smooth:true;sourceSize.width:168;sourceSize.height:160
                        opacity:splash.progress(0,160)
                        source:"data:image/svg+xml;charset=utf-8,"+encodeURIComponent('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 234 223"><path fill="'+owner.accent+'" fill-rule="evenodd" d="M 12 154 L 183 50 L 190 57 L 83 206 L 74 206 L 12 161 Z M 61 146 L 163 73 L 168 76 L 106 146 Z"/></svg>')
                    }
                }
                Item {
                    x:192/234*84;y:17/223*80;width:30/234*84;height:30/223*80
                    opacity:splash.progress(350,250)
                    scale:0.85+0.15*splash.progress(350,250)
                    Rectangle {anchors.centerIn:parent;width:parent.width/Math.SQRT2;height:width;rotation:45;color:"white"}
                }
            }
            Item {
                width:measure.width;height:80
                Text {id:measure;visible:false;text:"BY OPERATOR_";font.family:brandFont.name;font.pixelSize:43;font.letterSpacing:2}
                Text {
                    anchors.verticalCenter:parent.verticalCenter
                    text:"BY OPERATOR_".slice(0,Math.floor(12*splash.progress(550,700)))
                    color:"#c4d2cd";font:measure.font
                }
            }
        }
        Text {
            anchors.horizontalCenter:parent.horizontalCenter;y:901
            text:owner.keyboardHints ? "PRESS ANY KEY TO CONTINUE":"PRESS A BUTTON TO CONTINUE"
            visible:owner.preferences.splashWait
            opacity:splash.progress(1250,350)
            color:owner.preferences.highContrast ? "#f4f7f5":"#a5b9af"
            font.family:brandFont.name;font.pixelSize:20*owner.textScale;font.letterSpacing:3
        }
    }
    NumberAnimation {id:sequence;target:splash;property:"elapsed";from:0;to:1850;duration:1850}
    Timer {id:automatic;onTriggered:splash.dismiss()}
    NumberAnimation {id:exitFade;target:splash;property:"opacity";to:0;onStopped:if(splash.closing && splash.opacity===0) splash.finished()}
    MouseArea {
        anchors.fill:parent;acceptedButtons:Qt.AllButtons
        onPressed:automatic.stop()
        onClicked:{owner.observePointer();splash.dismiss();}
        onCanceled:if(splash.started && !owner.preferences.splashWait) automatic.restart()
        onWheel:wheel.accepted=true
    }
    Keys.onPressed: {
        event.accepted=true;
        // Pegasus maps stick motion and D-pad to arrows; never dismiss on those.
        if(event.isAutoRepeat || event.key===Qt.Key_Left || event.key===Qt.Key_Right || event.key===Qt.Key_Up || event.key===Qt.Key_Down) return;
        owner.observeInput(event);
        if(heldKey===-1) {heldKey=event.key;automatic.stop();}
    }
    Keys.onReleased: {
        event.accepted=true;
        if(!event.isAutoRepeat && event.key===heldKey) {heldKey=-1;splash.dismiss();}
    }
}

