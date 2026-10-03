import QtQuick 2.8
import QtMultimedia 5.8
FocusScope {
    id:player
    objectName:"relayTrailerPlayer"
    property var owner
    property string gameTitle:""
    property bool muted:false
    property int storedVolume:owner ? owner.preferences.trailerVolume:50
    signal closed()
    focus:true
    function start(url,title){gameTitle=title;media.source=url;media.play();}
    function toggle(){if(media.playbackState===MediaPlayer.PlayingState) media.pause();else media.play();}
    function seek(seconds){if(media.seekable) media.seek(Math.max(0,Math.min(media.duration,media.position+seconds*1000)));}
    function volume(delta){storedVolume=Math.max(0,Math.min(100,storedVolume+delta));owner.setPreference("trailerVolume",storedVolume);}
    function close(){media.stop();closed();}
    function timeLabel(ms){var seconds=Math.floor(ms/1000);return Math.floor(seconds/60)+":"+(seconds%60<10 ? "0":"")+seconds%60;}
    Rectangle {anchors.fill:parent;color:"#f8030605"}
    MouseArea {anchors.fill:parent;onClicked:player.forceActiveFocus();onWheel:wheel.accepted=true}
    MediaPlayer {
        id:media;objectName:"relayTrailerMedia"
        volume:player.muted ? 0:player.storedVolume/100
        autoPlay:false
    }
    VideoOutput {
        id:video;anchors.fill:parent;anchors.margins:60;anchors.topMargin:100;anchors.bottomMargin:130
        source:media;fillMode:VideoOutput.PreserveAspectFit
    }
    Text {
        anchors.left:parent.left;anchors.top:parent.top;anchors.margins:36
        width:parent.width-220;elide:Text.ElideRight
        text:"RELAY / TRAILER — "+player.gameTitle;color:owner ? owner.menuPalette.text:"white"
        font.family:owner ? owner.monoFont:"monospace";font.pixelSize:20*(owner ? owner.textScale:1)
    }
    Text {
        anchors.centerIn:parent;width:parent.width*.75;horizontalAlignment:Text.AlignHCenter;wrapMode:Text.WordWrap
        visible:media.error!==MediaPlayer.NoError || media.status===MediaPlayer.EndOfMedia || media.status===MediaPlayer.Loading
        text:media.error!==MediaPlayer.NoError ? "Could not play this trailer. The stream is unavailable or unsupported by this player.\n"+media.errorString:media.status===MediaPlayer.EndOfMedia ? (owner && !owner.keyboardHints ? "TRAILER FINISHED — PRESS ACCEPT TO REPLAY":"TRAILER FINISHED — PRESS ENTER TO REPLAY"):"LOADING TRAILER…"
        color:"white";font.family:owner ? owner.monoFont:"monospace";font.pixelSize:18*(owner ? owner.textScale:1)
    }
    Column {
        anchors.left:parent.left;anchors.right:parent.right;anchors.bottom:parent.bottom;anchors.margins:36;spacing:16
        Text {text:player.timeLabel(media.position)+" / "+player.timeLabel(media.duration)+"    VOLUME "+player.storedVolume+"%"+(player.muted ? " / MUTED":"");color:"#e3ece7";font.family:owner ? owner.monoFont:"monospace";font.pixelSize:14*(owner ? owner.textScale:1)}
        Rectangle {
            width:parent.width;height:5;color:"#35453c"
            Rectangle {width:parent.width*(media.duration>0 ? media.position/media.duration:0);height:5;color:owner ? owner.accent:"white"}
            MouseArea {anchors.fill:parent;anchors.margins:-8;onClicked:if(media.seekable) media.seek(media.duration*Math.max(0,Math.min(1,mouse.x/width)))}
        }
        Row {
            spacing:16
            Repeater {
                model:[media.playbackState===MediaPlayer.PlayingState ? "PAUSE":"PLAY",player.muted ? "UNMUTE":"MUTE","CLOSE"]
                Rectangle {
                    width:125;height:40;color:"#080e0b";border.color:owner ? owner.accent:"white";border.width:1
                    Text {anchors.centerIn:parent;text:modelData;color:"white";font.family:owner ? owner.monoFont:"monospace";font.pixelSize:14*(owner ? owner.textScale:1)}
                    MouseArea {anchors.fill:parent;onClicked:{if(index===0) player.toggle();else if(index===1) player.muted=!player.muted;else player.close();player.forceActiveFocus();}}
                }
            }
            Text {anchors.verticalCenter:parent.verticalCenter;text:owner && !owner.keyboardHints ? (owner.controllerStyle==="playstation" ? "CROSS: PLAY/PAUSE   CIRCLE: CLOSE   D-PAD: SEEK / VOLUME":"A: PLAY/PAUSE   B: CLOSE   D-PAD: SEEK / VOLUME"):"ENTER / SPACE: PLAY/PAUSE   ESC: CLOSE   ARROWS: SEEK / VOLUME   M: MUTE";color:"#b1c2b8";font.family:owner ? owner.monoFont:"monospace";font.pixelSize:12*(owner ? owner.textScale:1);width:Math.max(100,player.width-500);wrapMode:Text.WordWrap}
        }
    }
    Keys.onPressed:{
        if(owner) owner.observeInput(event);
        event.accepted=true;
        if(event.key===Qt.Key_Escape || owner.apiCancel(event)){if(!event.isAutoRepeat) player.close();}
        else if(event.key===Qt.Key_Return || event.key===Qt.Key_Enter || event.key===Qt.Key_Space || owner.apiAccept(event)){if(!event.isAutoRepeat) player.toggle();}
        else if(event.key===Qt.Key_Left) player.seek(-10);
        else if(event.key===Qt.Key_Right) player.seek(10);
        else if(event.key===Qt.Key_Up || event.key===Qt.Key_Plus || event.key===Qt.Key_Equal) player.volume(5);
        else if(event.key===Qt.Key_Down || event.key===Qt.Key_Minus) player.volume(-5);
        else if(event.key===Qt.Key_M && !event.isAutoRepeat) player.muted=!player.muted;
    }
    Component.onDestruction:media.stop()
}
