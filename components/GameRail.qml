import QtQuick 2.3

FocusScope {
    id: root
    property string fontFamily:"Consolas"
    objectName:"relayGameRail"
    property color accent: "#8fcdaa"
    property real textScale: 1
    property bool animationEnabled: true
    property var options
    property int direction: 1
    signal navigationSound(int direction)
    property var pointerObserver
    property var inputObserver
    property var settingsShortcut
    property var gameModel
    property var currentGame
    property int currentIndex: rail.currentIndex
    property bool modalOpen: false
    property bool navigationActive: true
    property var statusResolver
    property var artworkResolver
    property var frameResolver
    property var titleResolver
    signal activated()
    signal selectionRequested()
    signal favoriteRequested()
    signal previousTabRequested()
    signal nextTabRequested()
    signal sourceFilterRequested()
    signal previousSourceRequested()
    signal metadataRequested()
    signal actionsRequested()
    signal upperNavigationRequested()

    height: (options.cardWidth/(options.cardAspect/100)+46)*(options.cardScale/100)+32

    ListView {
        id: rail
        anchors.fill: parent
        orientation: ListView.Horizontal
        spacing: 22
        clip: false
        focus: !root.modalOpen && root.navigationActive
        enabled: !root.modalOpen
        model: root.gameModel
        currentIndex: 0
        keyNavigationWraps: false
        highlightMoveDuration: root.animationEnabled ? root.options.motionMs : 0
        preferredHighlightBegin: 0
        preferredHighlightEnd: width * 0.46
        highlightRangeMode: ListView.ApplyRange

        delegate: Item {
            id: cardSlot
            width: root.options.cardWidth
            height: width/(root.options.cardAspect/100)+46
            property bool selected: ListView.isCurrentItem
            z: selected ? 100 : 0
            Item {
                id: card;objectName:"relayGameCard"
                width: parent.width; height: parent.height
                property real artworkHeight: width/(root.options.cardAspect/100)
                property bool selected: cardSlot.selected
                property real yaw: 0
                property bool ready: false
                Component.onCompleted: ready=true
                transform: Rotation { origin.x: card.width/2; origin.y: card.height/2; axis.x: 0; axis.y: 1; axis.z: 0; angle: card.yaw }
                onSelectedChanged: {
                    incomingTurn.stop(); outgoingTurn.stop();
                    if(!ready || !root.animationEnabled) { yaw=0; return; }
                    if(selected) { yaw=-root.direction*root.options.cardTilt; incomingTurn.restart(); }
                    else { yaw=0; outgoingTurn.restart(); }
                }
                Connections { target: root; onAnimationEnabledChanged: if(!root.animationEnabled) { incomingTurn.stop(); outgoingTurn.stop(); card.yaw=0; } }
                NumberAnimation { id: incomingTurn; target: card; property: "yaw"; to:0; duration: root.options.motionMs; easing.type: Easing.OutCubic }
                SequentialAnimation {
                    id: outgoingTurn
                    NumberAnimation { target:card;property:"yaw";to:root.direction*root.options.cardTilt;duration:root.options.motionMs/2;easing.type:Easing.OutQuad }
                    NumberAnimation { target:card;property:"yaw";to:0;duration:root.options.motionMs/2;easing.type:Easing.OutQuad }
                }
                opacity: selected ? 1 : 0.82
                Behavior on opacity { NumberAnimation { duration: root.animationEnabled ? root.options.motionMs : 0 } }

            y: (root.height-height)/2
            scale: selected ? root.options.cardScale/100 : 1
            transformOrigin: Item.Center
            Behavior on y { NumberAnimation { duration: root.animationEnabled ? root.options.motionMs : 0;easing.type:root.options.animationLevel>1 ? Easing.OutBack:Easing.OutCubic } }
            Behavior on scale { NumberAnimation { duration: root.animationEnabled ? root.options.motionMs : 0 } }
            Rectangle {
                anchors.left:parent.left;anchors.right:parent.right;anchors.top:parent.top;height:card.artworkHeight
                radius: 0
                color: "#11161a"
                border.width: 1
                border.color: parent.selected ? root.accent : "#293036"
                opacity: parent.selected ? 1.0 : 0.72
            }
            FramedArtwork {
                crop:root.frameResolver ? root.frameResolver(modelData) : ({x:50,y:50,zoom:100})
                anchors.left:parent.left; anchors.right:parent.right; anchors.top:parent.top
                anchors.margins: 1; height:card.artworkHeight-2
                source: root.artworkResolver ? (root.artworkResolver(modelData, "boxFront") || root.artworkResolver(modelData, "background") || root.artworkResolver(modelData, "logo")) : (modelData.assets.boxFront || modelData.assets.background || modelData.assets.logo)
            }
            Text {
                anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
                anchors.leftMargin:10; anchors.rightMargin:10; anchors.bottomMargin:14; horizontalAlignment:Text.AlignHCenter
                text: root.titleResolver ? root.titleResolver(modelData) : modelData.title
                color: "#e7ebea"
                font.family:root.fontFamily; font.pixelSize: 15 * root.textScale
                elide: Text.ElideRight
            }
            Item {
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 10
                width: 30; height: 30
                anchors.topMargin: modelData.favorite ? 44 : 10
                visible: root.statusResolver ? root.statusResolver(modelData) !== "complete" && root.statusResolver(modelData) !== "manual" : true

                Rectangle {
                    anchors.centerIn: parent
                    width: 20; height: 20
                    rotation: 45
                    color: "#e6111618"
                    border.width: 1
                    border.color: root.statusResolver && root.statusResolver(modelData) === "incomplete" ? "#a65d5d" : "#b9a66d"
                }
                Text {
                    anchors.centerIn: parent
                    text: root.statusResolver && root.statusResolver(modelData) === "incomplete" ? "!" : "?"
                    color: root.statusResolver && root.statusResolver(modelData) === "incomplete" ? "#c97878" : "#d1bd78"
                    font.pixelSize: 13
                    font.bold: true
                }
            }
            Rectangle {
                anchors.right:parent.right; anchors.top:parent.top; anchors.margins:10
                width:26; height:26; radius:3; color:"#d0080d0b"; visible:!!modelData.favorite; z:19
                Text { anchors.centerIn:parent; text:"\u2665"; color:root.accent; font.family:"Segoe UI Symbol"; font.pixelSize:19 }
            }
            Rectangle {
                anchors.left:parent.left;anchors.right:parent.right;anchors.top:parent.top;height:card.artworkHeight;z:20
                color: "transparent"; border.width: parent.selected ? 1 : 0; border.color: root.accent
            }
            Rectangle {
                visible: parent.selected; z:20; anchors.horizontalCenter:parent.horizontalCenter; anchors.top:parent.bottom; anchors.topMargin:0
                width: parent.width*0.28; height:1; color:root.accent
            }
            MouseArea {
                anchors.fill: parent
                enabled: !root.modalOpen
                onClicked: { if(root.pointerObserver) root.pointerObserver(); root.direction=index>=rail.currentIndex ? 1:-1; if(index!==rail.currentIndex) root.navigationSound(root.direction); rail.currentIndex = index; root.selectionRequested(); rail.forceActiveFocus(); }
                onDoubleClicked: root.activated()
            }
            }
        }

        Keys.onPressed: {
            if (root.inputObserver) root.inputObserver(event);
            if (!root.modalOpen && (event.key === Qt.Key_S || event.key === Qt.Key_F1 || event.key === 1048582)) {
                event.accepted = true; if (!event.isAutoRepeat && root.settingsShortcut) root.settingsShortcut(); return;
            }
            if (root.modalOpen || !root.navigationActive) { event.accepted = false; return; }
            if(event.key===Qt.Key_F) { event.accepted=true; if(!event.isAutoRepeat) root.favoriteRequested(); return; }
            if (event.key === Qt.Key_Backspace || (event.key>=1048576 && event.key<=1048588 && api.keys.isFilters(event))) {
                event.accepted = true; if (!event.isAutoRepeat) root.metadataRequested(); return;
            }
            if (event.key === Qt.Key_Left) {
                event.accepted = true;
                if (rail.currentIndex > 0) { root.direction=-1; rail.currentIndex--; root.navigationSound(-1); }
            } else if (event.key === Qt.Key_Right) {
                event.accepted = true;
                if (rail.currentIndex < rail.count - 1) { root.direction=1; rail.currentIndex++; root.navigationSound(1); }
            } else if (api.keys.isAccept(event) && !event.isAutoRepeat) {
                event.accepted = true; root.activated();
            } else if (event.key === Qt.Key_Down) {
                event.accepted = true; root.actionsRequested();
            } else if (event.key === Qt.Key_Up) {
                event.accepted = true; root.upperNavigationRequested();
            } else if (event.key>=1048576 && event.key<=1048588 && api.keys.isDetails(event) && !event.isAutoRepeat) {
                event.accepted = true; root.favoriteRequested();
            } else if ((event.key === Qt.Key_Q || event.key === 1048580) && !event.isAutoRepeat) {
                event.accepted = true; root.previousTabRequested();
            } else if ((event.key === Qt.Key_E || event.key === 1048583) && !event.isAutoRepeat) {
                event.accepted = true; root.nextTabRequested();
            } else if ((event.key === Qt.Key_Tab || event.key === 1048584 || event.key === 1048581) && !event.isAutoRepeat) {
                event.accepted = true; if (event.key === 1048581 || (event.modifiers & Qt.ShiftModifier)) root.previousSourceRequested(); else root.sourceFilterRequested();
            }
        }
    }

    onGameModelChanged: Qt.callLater(function() { resetSelection(); })

    function resetSelection() {
        rail.currentIndex = gameModel && gameModel.count > 0 ? 0 : -1;
        if (rail.currentIndex >= 0) rail.positionViewAtIndex(0, ListView.Beginning);
        if (!root.modalOpen && root.navigationActive) rail.forceActiveFocus();
    }
}
