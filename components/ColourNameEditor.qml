import QtQuick 2.5
FocusScope {
    id:editor;objectName:"relayColourNameEditor";property var owner;property int selected:0
    readonly property var keys:"1234567890QWERTYUIOPASDFGHJKL".split("").concat(["DELETE"]).concat("ZXCVBNM".split("")).concat(["SPACE","SAVE","CANCEL"])
    function begin() { nameInput.text="";owner.colourMessage="";selected=10;restoreFocus(); }
    function restoreFocus() {nameInput.focus=false;forceActiveFocus();if(owner.keyboardHints) nameInput.forceActiveFocus();}
    function close() {owner.colourEditorOpen=false;owner.openSettings();}
    function useKey(i) {
        var key=keys[i];if(key==="SAVE") owner.saveNamedColour(nameInput.text);
        else if(key==="CANCEL") close();else if(key==="DELETE") nameInput.text=nameInput.text.slice(0,-1);
        else if(nameInput.text.length<32) nameInput.text+=key==="SPACE" ? " ":key;
    }
    Rectangle {anchors.fill:parent;color:editor.owner.menuPalette.backdrop;MouseArea {anchors.fill:parent;onClicked:{} onWheel:wheel.accepted=true}}
    Rectangle {
        anchors.centerIn:parent;width:Math.min(parent.width*0.85,900);height:500;color:editor.owner.menuPalette.panel;border.width:1;border.color:editor.owner.menuPalette.focusColor
        Column {anchors.fill:parent;anchors.margins:30;spacing:22
            Text {text:"RELAY / SAVE ACCENT COLOUR";color:editor.owner.menuPalette.focusColor;font.family:editor.owner.monoFont;font.pixelSize:20}
            Text {text:"Type a name or use the QWERTY keys. Duplicate names ask before overwriting.";color:editor.owner.menuPalette.muted;font.family:editor.owner.monoFont;font.pixelSize:12}
            Rectangle {width:parent.width;height:45;color:editor.owner.menuPalette.selectedFill;border.color:editor.owner.menuPalette.focusColor;border.width:1
                TextInput {id:nameInput;objectName:"relayColourNameInput";anchors.fill:parent;anchors.margins:10;maximumLength:32;selectByMouse:true;color:editor.owner.menuPalette.focusColor;font.family:editor.owner.monoFont;font.pixelSize:18
                    onTextChanged:if(editor.owner) editor.owner.colourMessage=""
                    Keys.onPressed:{editor.owner.observeInput(event);if(event.key===Qt.Key_Escape){editor.close();event.accepted=true;}else if(event.key===Qt.Key_Return || event.key===Qt.Key_Enter){editor.owner.saveNamedColour(text);event.accepted=true;}else if(event.key===Qt.Key_Tab || event.key>=1048576 && event.key<=1048588){editor.forceActiveFocus();event.accepted=true;}}
                }
            }
            Text {visible:editor.owner.colourMessage.length>0;text:editor.owner.colourMessage;color:editor.owner.menuPalette.focusColor;font.family:editor.owner.monoFont;font.pixelSize:12}
            Grid {width:parent.width;columns:10;spacing:5
                Repeater {model:editor.keys
                    Rectangle {width:(parent.width-45)/10;height:40;color:index===editor.selected ? editor.owner.menuPalette.selectedFill:"transparent";border.width:1;border.color:index===editor.selected ? editor.owner.menuPalette.focusColor:editor.owner.menuPalette.line
                        Text {anchors.centerIn:parent;text:modelData===" " ? "SPACE":modelData;color:editor.owner.menuPalette.focusColor;font.family:editor.owner.monoFont;font.pixelSize:12}
                        MouseArea {anchors.fill:parent;onClicked:{editor.owner.observePointer();editor.selected=index;editor.useKey(index);}}
                    }
                }
            }
            Text {text:editor.owner.keyboardHints ? "[ENTER] SAVE   [TAB] ON-SCREEN KEYS   [ESC] CANCEL":"D-PAD CHOOSE / A TYPE / B CANCEL";color:editor.owner.menuPalette.muted;font.family:editor.owner.monoFont;font.pixelSize:12}
        }
    }
    Keys.onPressed:{
        editor.owner.observeInput(event);event.accepted=true;
        if(api.keys.isCancel(event) || event.key===Qt.Key_Escape) close();
        else if(api.keys.isAccept(event) || event.key===Qt.Key_Return || event.key===Qt.Key_Enter) {if(!event.isAutoRepeat) useKey(selected);}
        else if(event.key===Qt.Key_Left) selected=(selected-1+keys.length)%keys.length;
        else if(event.key===Qt.Key_Right) selected=(selected+1)%keys.length;
        else if(event.key===Qt.Key_Up) selected=Math.max(0,selected-10);
        else if(event.key===Qt.Key_Down) selected=Math.min(keys.length-1,selected+10);
        else if(event.key===Qt.Key_Tab) nameInput.forceActiveFocus();
        else if(event.key===Qt.Key_Backspace) nameInput.text=nameInput.text.slice(0,-1);
        else if(event.text && !(event.modifiers & (Qt.ControlModifier | Qt.AltModifier))) {nameInput.forceActiveFocus();if(nameInput.text.length<32) nameInput.text+=event.text;}
    }
}

