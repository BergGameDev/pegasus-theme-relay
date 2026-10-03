import QtQuick 2.5
Rectangle {
    id: picker
    property var owner
    property string kind: "hero"
    property int slot: 0
    property string label: "HERO ARTWORK"
    property bool crop: false
    readonly property var choices: owner.artworkData[kind] || []
    readonly property int choiceIndex: kind==="hero" ? owner.heroIndex : kind==="cover" ? owner.coverIndex : owner.logoIndex
    readonly property bool selected: owner.curationIndex===slot
    readonly property bool canBrowse: choices.length>1 && !owner.applyBusy && !owner.artworkLoading
    color: owner.menuPalette.surface; border.width:1; border.color:selected ? owner.accent : owner.menuPalette.line
    Image {
        id:preview
        anchors.fill:parent;anchors.margins:crop ? 2 : 10
        anchors.topMargin:crop ? 2 : 28;anchors.bottomMargin:crop ? 2 : 24
        source:picker.choices.length ? picker.choices[picker.choiceIndex].url : ""
        fillMode:picker.crop ? Image.PreserveAspectCrop : Image.PreserveAspectFit
        asynchronous:true;smooth:true;mipmap:true
    }
    MouseArea {
        anchors.fill:parent;enabled:!picker.owner.applyBusy
        onClicked:{picker.owner.observePointer();picker.owner.selectArtwork(picker.slot)}
    }
    Text { anchors.left:parent.left;anchors.top:parent.top;anchors.margins:8;z:2;text:picker.label;color:picker.selected ? picker.owner.accent : picker.owner.menuPalette.text;font.family:picker.owner.monoFont;font.pixelSize:11*picker.owner.textScale;font.letterSpacing:1 }
    Text { anchors.centerIn:parent;z:2;visible:picker.owner.artworkLoading || !picker.choices.length;text:picker.owner.artworkLoading ? "LOADING..." : "NO ARTWORK FOUND";color:picker.owner.menuPalette.muted;font.family:picker.owner.monoFont;font.pixelSize:12*picker.owner.textScale }
    Rectangle {
        anchors.right:parent.right;anchors.bottom:parent.bottom;anchors.margins:6;width:counter.implicitWidth+12;height:20;z:2
        color:picker.owner.menuPalette.backdrop
        Text { id:counter;anchors.centerIn:parent;text:picker.choices.length ? (picker.choiceIndex+1)+" / "+picker.choices.length : "0 / 0";color:picker.owner.menuPalette.text;font.family:picker.owner.monoFont;font.pixelSize:11*picker.owner.textScale }
    }
    Rectangle {
        anchors.right:parent.right;anchors.top:parent.top;anchors.margins:6;z:2
        visible:preview.status===Image.Ready;width:dimensions.implicitWidth+12;height:20;color:picker.owner.menuPalette.backdrop
        Text {id:dimensions;anchors.centerIn:parent;text:preview.sourceSize.width+" x "+preview.sourceSize.height;color:picker.owner.menuPalette.text;font.family:picker.owner.monoFont;font.pixelSize:11*picker.owner.textScale}
    }
    Repeater {
        model:2
        Rectangle {
            objectName:picker.kind+(index===0 ? "PreviousArtwork" : "NextArtwork")
            property bool previous: index===0
            anchors.verticalCenter:parent.verticalCenter
            x:previous ? 6 : picker.width-width-6
            width:32;height:40;z:3
            visible:picker.choices.length>1 && picker.selected && picker.owner.artworkEditMode
            opacity:picker.canBrowse ? 1 : 0.35
            color:arrowMouse.containsMouse ? picker.owner.menuPalette.hoverFill : picker.owner.menuPalette.panel
            border.width:1;border.color:picker.selected || arrowMouse.containsMouse ? picker.owner.accent : picker.owner.menuPalette.line
            Item {
                anchors.centerIn:parent;width:12;height:16;scale:parent.previous ? 1 : -1
                Rectangle { x:2;y:4;width:10;height:1;rotation:-45;color:picker.owner.accent }
                Rectangle { x:2;y:11;width:10;height:1;rotation:45;color:picker.owner.accent }
            }
            MouseArea { id:arrowMouse;anchors.fill:parent;hoverEnabled:true;enabled:picker.canBrowse;onClicked:{picker.owner.observePointer();picker.owner.browseArtwork(picker.slot,parent.previous ? -1 : 1)}}
        }
    }
    Rectangle {
        visible:picker.selected && !picker.owner.artworkEditMode && picker.choices.length>0
        anchors.left:parent.left;anchors.bottom:parent.bottom;anchors.margins:6;width:picker.kind==="cover" ? 300:140;height:24;z:2;color:picker.owner.menuPalette.backdrop
        Row { anchors.centerIn:parent;spacing:16
            ControlPrompt { owner:picker.owner;keyText:"ENTER";buttons:picker.owner.promptButtons("accept");label:"ADJUST";iconSize:18 }
            Item { visible:picker.kind==="cover";width:cropCue.width;height:cropCue.height;ControlPrompt { id:cropCue;owner:picker.owner;keyText:"BACKSPACE";buttons:picker.owner.promptButtons("filters");label:"CROP";iconSize:18 } MouseArea { anchors.fill:parent;onClicked:{picker.owner.observePointer();picker.owner.openCropEditor()}} }
        }
    }
}
