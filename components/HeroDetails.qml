import QtQuick 2.5
Item {
    id: details
    objectName: "relayHeroDetails"
    property var game
    property url logoSource
    property string title: ""
    property string developerText: ""
    property string synopsis: ""
    property var options
    property real textScale: 1
    property string fontFamily: "Consolas"
    property int phase: 0
    property real logoOpacity: 0
    property real ruleProgress: 0
    readonly property real dividerWidth: Math.min(width*0.72,460)
    readonly property bool typing: options.animation && options.typewriter
    function restart() {
        entrance.stop(); waitForLogo.stop(); phase=0; logoOpacity=0; ruleProgress=0;
        Qt.callLater(function() {
            if(!String(logoSource) || logo.status===Image.Ready || logo.status===Image.Error) begin();
            else waitForLogo.restart();
        });
    }
    function begin() {
        if(phase!==0) return;
        waitForLogo.stop();
        if(!options.animation) { phase=4;logoOpacity=1;ruleProgress=1;return; }
        phase=1; entrance.restart();
    }
    onGameChanged: restart()
    onLogoSourceChanged: restart()
    onOptionsChanged: if(!options.animation) { entrance.stop(); waitForLogo.stop(); phase=4;logoOpacity=1;ruleProgress=1; }
    Component.onCompleted: restart()
    Timer { id:waitForLogo;interval:1200;onTriggered:details.begin() }
    SequentialAnimation {
        id: entrance
        NumberAnimation { target:details;property:"logoOpacity";from:0;to:1;duration:180 }
        ScriptAction { script:details.phase=2 }
        NumberAnimation { target:details;property:"ruleProgress";from:0;to:1;duration:120 }
        ScriptAction { script:{ details.phase=3;Qt.callLater(function(){if(!details.typing || !details.developerText.length) details.phase=4;}); } }
    }
    Item {
        id: titleSlot; width:parent.width; height:150
        Image {
            id:logo;objectName:"relayDetailsLogo"
            width:Math.min(titleSlot.width*0.82,620);height:150
            x: paintedWidth<details.dividerWidth ? (details.dividerWidth-paintedWidth)/2 : 0
            source:details.logoSource;sourceSize.width:Math.round(width);sourceSize.height:150
            fillMode:Image.PreserveAspectFit;horizontalAlignment:Image.AlignLeft;verticalAlignment:Image.AlignVCenter
            asynchronous:true;smooth:true;mipmap:true
            visible:String(details.logoSource)!=="" && status===Image.Ready
            opacity:details.logoOpacity
            onStatusChanged: if(status===Image.Ready || status===Image.Error) details.begin()
        }
        Text {
            objectName:"relayDetailsTitle";anchors.fill:parent
            visible:!String(details.logoSource) || logo.status===Image.Error
            text:visible ? details.title : "";opacity:details.logoOpacity
            color:"#f0f2f1";font.family:details.fontFamily;font.pixelSize:42*details.textScale;font.weight:Font.DemiBold
            wrapMode:Text.WordWrap;maximumLineCount:2;elide:Text.ElideRight;verticalAlignment:Text.AlignVCenter
        }
    }
    Rectangle {
        id:rule;objectName:"relayDetailsRule";y:titleSlot.height+14;width:details.dividerWidth*details.ruleProgress;height:1
        color:"#44504d";visible:!!details.game
    }
    TypewriterLabel {
        id:meta;objectName:"relayDetailsMeta";y:rule.y+14;width:parent.width
        fullText:details.developerText;active:details.phase>=3;blankUntilActive:true
        animateTyping:details.typing;characterMs:details.options.metadataMs
        color:"#89938f";font.family:details.fontFamily;font.pixelSize:14*details.textScale;font.letterSpacing:1.5
        elide:Text.ElideRight
        onRevealedChanged: if(details.phase===3 && revealed>=fullText.length) details.phase=4
    }
    TypewriterLabel {
        objectName:"relayDetailsSynopsis";y:meta.y+meta.height+22;width:parent.width*0.94;height:Math.max(0,parent.height-y)
        fullText:details.synopsis;active:details.phase>=4;blankUntilActive:true
        animateTyping:details.typing;characterMs:details.options.synopsisMs
        visible:details.options.synopsis && fullText.length>0
        color:"#b4bdb9";font.family:details.fontFamily;font.pixelSize:18*details.textScale
        lineHeight:1.35;wrapMode:Text.WordWrap;maximumLineCount:5;elide:Text.ElideRight;clip:true
    }
}
