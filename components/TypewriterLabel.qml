import QtQuick 2.5
Text {
    id: label
    property string fullText: ""
    property bool active: false
    property bool animateTyping: true
    property bool cursorBlink:true
    property bool showCursor: false
    property bool blankUntilActive: false
    property int characterMs: 38
    property int blinkMs: 550
    property int revealed: fullText.length
    property bool cursorOn: true
    text: blankUntilActive && !active ? "" : fullText.slice(0,revealed) + (active && showCursor && (!cursorBlink || cursorOn) ? "_" : "")
    width: measure.implicitWidth
    Text { id: measure; visible: false; text: label.fullText + (label.showCursor ? "_" : ""); font: label.font }
    function restart() { revealed = active && animateTyping ? 0 : fullText.length; cursorOn = true; }
    onFullTextChanged: restart()
    onActiveChanged: restart()
    onAnimateTypingChanged: restart()
    Timer { interval: Math.max(1,label.characterMs); repeat: true; running: label.active && label.animateTyping && label.revealed<label.fullText.length; onTriggered: label.revealed++ }
    Timer { interval: Math.max(200,label.blinkMs); repeat: true; running: label.cursorBlink && label.active && label.showCursor && label.animateTyping && label.revealed>=label.fullText.length; onTriggered: label.cursorOn=!label.cursorOn }
}
