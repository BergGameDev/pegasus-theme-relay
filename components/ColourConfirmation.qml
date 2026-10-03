import QtQuick 2.5
FocusScope {
    id:dialog;objectName:"relayColourConfirmation";property var owner;property int selected:0
    Rectangle {anchors.fill:parent;color:dialog.owner.menuPalette.backdrop;MouseArea {anchors.fill:parent;onClicked:{} onWheel:wheel.accepted=true}}
    Rectangle {anchors.centerIn:parent;width:Math.min(parent.width*.8,760);height:260;color:dialog.owner.menuPalette.panel;border.width:1;border.color:dialog.owner.menuPalette.focusColor
        Text {anchors.left:parent.left;anchors.top:parent.top;anchors.margins:28;text:dialog.owner.colourConfirmation==="delete" ? "REMOVE ACCENT COLOUR?":"OVERWRITE ACCENT COLOUR?";color:dialog.owner.menuPalette.focusColor;font.family:dialog.owner.monoFont;font.pixelSize:18}
        Text {anchors.left:parent.left;anchors.right:parent.right;anchors.top:parent.top;anchors.margins:28;anchors.topMargin:76;wrapMode:Text.Wrap;text:dialog.owner.colourConfirmationText;color:dialog.owner.menuPalette.text;font.family:dialog.owner.monoFont;font.pixelSize:14}
        Row {anchors.horizontalCenter:parent.horizontalCenter;anchors.bottom:parent.bottom;anchors.bottomMargin:28;spacing:22
            Repeater {model:["CANCEL",dialog.owner.colourConfirmation==="delete" ? "REMOVE":"OVERWRITE"]
                Rectangle {width:160;height:42;color:dialog.selected===index ? dialog.owner.menuPalette.selectedFill:"transparent";border.width:1;border.color:dialog.selected===index ? dialog.owner.menuPalette.focusColor:dialog.owner.menuPalette.line
                    Text {anchors.centerIn:parent;text:modelData;color:dialog.owner.menuPalette.focusColor;font.family:dialog.owner.monoFont;font.pixelSize:14}
                    MouseArea {anchors.fill:parent;onClicked:{dialog.owner.observePointer();dialog.owner.finishColourConfirmation(index===1);}}
                }
            }
        }
    }
    Keys.onPressed:{dialog.owner.observeInput(event);event.accepted=true;
        if(api.keys.isCancel(event) || event.key===Qt.Key_Escape) dialog.owner.finishColourConfirmation(false);
        else if(event.key===Qt.Key_Left || event.key===Qt.Key_Right || event.key===Qt.Key_Tab) selected=1-selected;
        else if(api.keys.isAccept(event) || event.key===Qt.Key_Return || event.key===Qt.Key_Enter) {if(!event.isAutoRepeat) dialog.owner.finishColourConfirmation(selected===1);}
    }
}
