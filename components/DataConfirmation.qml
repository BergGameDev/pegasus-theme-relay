import QtQuick 2.5
FocusScope {
    id: dialog;objectName:"relayDataConfirmation"
    property var owner
    property int selected:0
    property bool clearing:owner.dataConfirmation==="clear"
    onVisibleChanged:if(visible) {selected=0;Qt.callLater(function(){if(dialog.visible) dialog.forceActiveFocus();});}
    Rectangle {anchors.fill:parent;color:dialog.owner.menuPalette.backdrop;MouseArea {anchors.fill:parent;onClicked:{} onWheel:wheel.accepted=true}}
    Rectangle {
        anchors.centerIn:parent;width:Math.min(parent.width*.88,850);height:Math.min(parent.height*.8,340)
        color:dialog.owner.menuPalette.panel;border.width:2;border.color:dialog.owner.menuPalette.focusColor
        Column {
            anchors.fill:parent;anchors.margins:28;spacing:20
            Text {width:parent.width;text:dialog.clearing ? "CLEAR RELAY GAME DATA?":"DISCARD UNSAVED CHANGES?";wrapMode:Text.Wrap;color:dialog.owner.menuPalette.focusColor;font.family:dialog.owner.monoFont;font.pixelSize:20*dialog.owner.textScale}
            Text {width:parent.width;text:dialog.owner.gameTitleText(dialog.owner.currentGame);elide:Text.ElideRight;color:dialog.owner.menuPalette.text;font.family:dialog.owner.monoFont;font.pixelSize:18*dialog.owner.textScale}
            Text {width:parent.width;wrapMode:Text.Wrap;text:dialog.clearing ? "Removes this game's Relay-generated metadata and downloaded artwork, plus any unsaved edits. Your game files and other providers' metadata are not removed.":"Your metadata, artwork or crop changes have not been applied. Keep editing, or discard them and go back.";color:dialog.owner.menuPalette.text;font.family:dialog.owner.monoFont;font.pixelSize:14*dialog.owner.textScale}
        }
        Row {
            anchors.horizontalCenter:parent.horizontalCenter;anchors.bottom:parent.bottom;anchors.bottomMargin:28;spacing:20
            Repeater {model:[dialog.clearing ? "CANCEL":"KEEP EDITING",dialog.clearing ? "CLEAR":"DISCARD"]
                Rectangle {width:Math.min(220,(dialog.width*.88-100)/2);height:48;color:dialog.selected===index ? dialog.owner.menuPalette.selectedFill:"transparent";border.width:dialog.selected===index ? 2:1;border.color:dialog.selected===index ? dialog.owner.menuPalette.focusColor:dialog.owner.menuPalette.line
                    Text {anchors.centerIn:parent;text:modelData;color:dialog.owner.menuPalette.text;font.family:dialog.owner.monoFont;font.pixelSize:14*dialog.owner.textScale}
                    MouseArea {anchors.fill:parent;onClicked:dialog.owner.finishDataConfirmation(index===1)}
                }
            }
        }
    }
    Keys.onPressed:{
        owner.observeInput(event);event.accepted=true;if(event.isAutoRepeat)return;
        if(event.key===Qt.Key_Escape || owner.apiCancel(event)) owner.finishDataConfirmation(false);
        else if(event.key===Qt.Key_Left || event.key===Qt.Key_Right || event.key===Qt.Key_Tab || event.key===Qt.Key_Backtab) selected=1-selected;
        else if(event.key===Qt.Key_Return || event.key===Qt.Key_Enter || owner.apiAccept(event)) owner.finishDataConfirmation(selected===1);
    }
    Keys.onReleased:event.accepted=true
}


