import QtQuick 2.5
Rectangle {
    id:editor;property var owner;color:owner.menuPalette.backdrop
    MouseArea { anchors.fill:parent;onClicked:{editor.owner.observePointer();} onWheel:wheel.accepted=true }
    Rectangle {
        anchors.centerIn:parent;width:Math.min(parent.width*0.80,980);height:Math.min(parent.height*0.84,710)
        color:editor.owner.menuPalette.panel;border.width:1;border.color:editor.owner.menuPalette.focusColor
        Rectangle {
            anchors.right:parent.right;anchors.top:parent.top;anchors.margins:16;width:30;height:30;color:"transparent";border.width:1;border.color:editor.owner.menuPalette.focusColor
            Text { anchors.centerIn:parent;text:"X";color:editor.owner.menuPalette.focusColor;font.family:editor.owner.monoFont }
            MouseArea { anchors.fill:parent;onClicked:{editor.owner.observePointer();editor.owner.finishCrop()}}
        }
        Column {
            anchors.fill:parent;anchors.margins:30;spacing:24
            Text { text:"RELAY / THUMBNAIL CROP";color:editor.owner.menuPalette.focusColor;font.family:editor.owner.monoFont;font.pixelSize:20*editor.owner.textScale;font.letterSpacing:2 }
            Text { text:"ARROWS MOVE THE IMAGE / APPLY IN GAME DATA SAVES THIS CROP";color:editor.owner.menuPalette.muted;font.family:editor.owner.monoFont;font.pixelSize:12*editor.owner.textScale;width:parent.width;wrapMode:Text.Wrap }
            FramedArtwork {
                anchors.horizontalCenter:parent.horizontalCenter;width:Math.min(parent.width,820,Math.max(180,(parent.height-260)*(editor.owner.preferences.cardAspect/100)));height:width/(editor.owner.preferences.cardAspect/100)
                source:editor.owner.cropSource;crop:editor.owner.cropDraft
                MouseArea {
                    anchors.fill:parent;property real lastX;property real lastY
                    onPressed:{editor.owner.observePointer();lastX=mouse.x;lastY=mouse.y;}
                    onPositionChanged:if(pressed){editor.owner.panCrop((mouse.x-lastX)/8,(mouse.y-lastY)/8);lastX=mouse.x;lastY=mouse.y;}
                    onWheel:wheel.accepted=true
                }
            }
            Text { anchors.horizontalCenter:parent.horizontalCenter;text:"POSITION "+Math.round(editor.owner.cropDraft.x)+" / "+Math.round(editor.owner.cropDraft.y)+"    ZOOM "+editor.owner.cropDraft.zoom+" %";color:editor.owner.menuPalette.text;font.family:editor.owner.monoFont;font.pixelSize:14*editor.owner.textScale }
        }
        Row { id:cropControls;anchors.horizontalCenter:parent.horizontalCenter;anchors.bottom:parent.bottom;anchors.bottomMargin:26;spacing:22
                ControlPrompt { owner:editor.owner;keyText:"ARROWS";buttons:editor.owner.promptButtons("navigate");label:"POSITION" }
                ControlPrompt { owner:editor.owner;keyText:"- / +";buttons:["lt","rt"];label:"ZOOM" }
                ControlPrompt { owner:editor.owner;keyText:"R";buttons:["y"];label:"RESET" }
                ControlPrompt { owner:editor.owner;keyText:"ESC / ENTER";buttons:["b","a"];label:"BACK" }
            }
            Text { anchors.left:parent.left;anchors.right:parent.right;anchors.leftMargin:30;anchors.rightMargin:30;anchors.bottom:cropControls.top;anchors.bottomMargin:18;wrapMode:Text.Wrap;text:"Crop changes remain a draft until APPLY. Different cover artwork resets the crop.";color:editor.owner.menuPalette.muted;font.family:editor.owner.monoFont;font.pixelSize:12*editor.owner.textScale }
    }
}
