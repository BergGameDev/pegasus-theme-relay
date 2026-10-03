import QtQuick 2.9
FocusScope {
    id:editor;property var owner
    function focusRow() {
        if(owner.keyboardHints && owner.metadataField<6) fields.itemAt(owner.metadataField).focusInput();
        else forceActiveFocus();
    }
    Rectangle { anchors.fill:parent;color:editor.owner.menuPalette.backdrop }
    MouseArea { anchors.fill:parent;onClicked:{editor.owner.observePointer();} }
    Rectangle {
        anchors.centerIn:parent;width:Math.min(parent.width*0.84,1100);height:Math.min(parent.height*0.9,780)
        color:editor.owner.menuPalette.panel;border.width:1;border.color:editor.owner.menuPalette.focusColor
        Column {
            anchors.fill:parent;anchors.margins:30;spacing:12
            Text { text:"RELAY / EDIT METADATA";color:editor.owner.menuPalette.focusColor;font.family:editor.owner.monoFont;font.pixelSize:20*editor.owner.textScale;font.letterSpacing:2 }
            Text { text:"EDIT THE CURRENT ENTRY / APPLY SAVES TO THE LIBRARY";color:editor.owner.menuPalette.muted;font.family:editor.owner.monoFont;font.pixelSize:12*editor.owner.textScale }
            Repeater {
                id:fields;model:["TITLE","DEVELOPER","PUBLISHER","GENRES (COMMA SEPARATED)","RELEASE YEAR","SYNOPSIS"]
                Rectangle {
                    width:parent.width;height:58;color:editor.owner.metadataField===index ? editor.owner.menuPalette.selectedFill : "transparent"
                    border.width:editor.owner.metadataField===index ? 1:0;border.color:editor.owner.menuPalette.focusColor
                    function focusInput() { input.forceActiveFocus(); }
                    Text { anchors.left:parent.left;anchors.top:parent.top;anchors.margins:10;text:modelData;color:editor.owner.menuPalette.muted;font.family:editor.owner.monoFont;font.pixelSize:11*editor.owner.textScale }
                    TextInput {
                        id:input;anchors.left:parent.left;anchors.right:parent.right;anchors.bottom:parent.bottom;anchors.margins:10
                        text:editor.owner.metadataDraft[editor.owner.metadataFields[index]] || "";readOnly:!editor.owner.keyboardHints
                        color:editor.owner.metadataField===index ? editor.owner.menuPalette.focusColor : editor.owner.menuPalette.text
                        selectionColor:editor.owner.menuPalette.hoverFill;selectedTextColor:editor.owner.menuPalette.focusColor
                        font.family:editor.owner.monoFont;font.pixelSize:15*editor.owner.textScale;clip:true;selectByMouse:true
                        onActiveFocusChanged: if(activeFocus) editor.owner.metadataField=index
                        onTextEdited:editor.owner.setMetadataDraft(editor.owner.metadataFields[index],text)
                        Keys.onPressed:editor.owner.handleMetadataKey(event)
                    }
                    MouseArea { anchors.fill:parent;enabled:!editor.owner.keyboardHints;onClicked:{editor.owner.observePointer();editor.owner.metadataField=index;editor.owner.editMetadataFieldOnPad();} }
                }
            }
            Rectangle {
                width:parent.width;height:42;color:editor.owner.metadataField===6 ? editor.owner.menuPalette.selectedFill : "transparent"
                border.width:1;border.color:editor.owner.menuPalette.focusColor
                Text { anchors.centerIn:parent;text:"KEEP CHANGES";color:editor.owner.menuPalette.focusColor;font.family:editor.owner.monoFont;font.pixelSize:14*editor.owner.textScale }
                MouseArea { anchors.fill:parent;onClicked:{editor.owner.observePointer();editor.owner.saveMetadataDraft()}}
            }
            Text { text:!editor.owner.metadataDraft.title.trim() ? "Title is required." : editor.owner.metadataDraft.year.trim() && (!/^\d{4}$/.test(editor.owner.metadataDraft.year) || parseInt(editor.owner.metadataDraft.year)<1900 || parseInt(editor.owner.metadataDraft.year)>2200) ? "Release year must be between 1900 and 2200." : "Keep Changes returns to Game Data. APPLY writes the entry.";color:editor.owner.menuPalette.muted;font.family:editor.owner.monoFont;font.pixelSize:12*editor.owner.textScale }
            Row { spacing:24
                ControlPrompt { owner:editor.owner;keyText:"TAB / ARROWS";buttons:editor.owner.promptButtons("navigate");label:"FIELD" }
                ControlPrompt { owner:editor.owner;keyText:"ENTER";buttons:editor.owner.promptButtons("accept");label:"EDIT / KEEP" }
                ControlPrompt { owner:editor.owner;keyText:"ESC";buttons:editor.owner.promptButtons("cancel");label:"CANCEL" }
            }
        }
        Rectangle {
            anchors.top:parent.top;anchors.right:parent.right;anchors.margins:16;width:30;height:30;color:"transparent";border.width:1;border.color:editor.owner.menuPalette.focusColor
            Text { anchors.centerIn:parent;text:"X";color:editor.owner.menuPalette.focusColor;font.family:editor.owner.monoFont }
            MouseArea { anchors.fill:parent;onClicked:{editor.owner.observePointer();editor.owner.cancelMetadataDraft()}}
        }
    }
    Keys.onPressed:owner.handleMetadataKey(event)
}
