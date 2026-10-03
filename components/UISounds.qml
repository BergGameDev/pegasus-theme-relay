import QtQuick 2.3
import QtMultimedia 5.0
Item {
    id:sounds;objectName:"relaySounds"
    property int pack:0
    function clip(name) { return "../assets/sounds/"+(["","synth/","pulse/","glass/"][pack] || "")+name+".wav"; }
    property bool enabled:false
    property real level:0.24
    property int transitionKind:1
    property real transitionLevel:0.25
    function transitionClip() {return "../assets/sounds/transition/"+(["swish","swish","whoosh","signal"][transitionKind] || "swish")+".wav";}
    function transition() {if(enabled && level>0 && transitionLevel>0 && transitionKind>0) fire(swishA,swishB);}
    function fire(first,second) {
        var voice=first;
        if((first.status!==SoundEffect.Ready || first.playing) && second && second.status===SoundEffect.Ready) voice=second;
        if(voice.status===SoundEffect.Ready) {
            if(voice.playing) voice.stop();
            voice.play();
        }
    }
    property string lastKind:""
    function play(kind) {
        if(!enabled || level<=0) return;
        lastKind=kind;
        if(kind==="left") fire(leftA,leftB);
        else if(kind==="right") fire(rightA,rightB);
        else if(kind==="category") fire(categoryA,categoryB);
        else if(kind==="source") fire(sourceA,sourceB);
        else if(kind==="playFocus") fire(playFocus,null);
        else if(kind==="settings") fire(settingsA,settingsB);
        else if(kind==="launch") {if(playFocus.playing) playFocus.stop();fire(launchCue,null); }
        else if(kind==="confirm") fire(confirm,null);
        else if(kind==="back") fire(back,null);
        else fire(moveA,moveB);
    }
    SoundEffect { id:leftA;source:sounds.clip("left");volume:sounds.level*0.7 }
    SoundEffect { id:leftB;source:sounds.clip("left");volume:sounds.level*0.7 }
    SoundEffect { id:rightA;source:sounds.clip("right");volume:sounds.level*0.7 }
    SoundEffect { id:rightB;source:sounds.clip("right");volume:sounds.level*0.7 }
    SoundEffect { id:categoryA;source:sounds.clip("source");volume:sounds.level*0.7 }
    SoundEffect { id:categoryB;source:sounds.clip("source");volume:sounds.level*0.7 }
    SoundEffect { id:sourceA;source:sounds.clip("category");volume:sounds.level*0.7 }
    SoundEffect { id:sourceB;source:sounds.clip("category");volume:sounds.level*0.7 }
    SoundEffect { id:moveA;source:sounds.clip("move");volume:sounds.level*0.8 }
    SoundEffect { id:moveB;source:sounds.clip("move");volume:sounds.level*0.8 }
    SoundEffect { id:settingsA;source:sounds.clip("settings");volume:sounds.level*0.7 }
    SoundEffect { id:settingsB;source:sounds.clip("settings");volume:sounds.level*0.7 }
    SoundEffect { id:playFocus;source:sounds.clip("play-focus");volume:sounds.level*0.85 }
    SoundEffect { id:confirm;source:sounds.clip("confirm");volume:sounds.level*0.75 }
    SoundEffect { id:swishA;source:sounds.transitionClip();volume:sounds.level*sounds.transitionLevel }
    SoundEffect { id:swishB;source:sounds.transitionClip();volume:sounds.level*sounds.transitionLevel }
    SoundEffect { id:launchCue;source:sounds.clip("launch");volume:sounds.level*0.75 }
    SoundEffect { id:back;source:sounds.clip("back");volume:sounds.level*0.65 }
}
