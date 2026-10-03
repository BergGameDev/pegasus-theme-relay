import QtQuick 2.3
Image {
    id: mark
    objectName: "operatorMark"
    property color accent: "#39ddb0"
    // Re-render the vector only on colour/size changes; no animation or effect pass.
    function rgb(c) {
        function channel(v) { return ("0"+Math.round(v*255).toString(16)).slice(-2); }
        return "#"+channel(c.r)+channel(c.g)+channel(c.b);
    }
    source: "data:image/svg+xml;charset=utf-8,"+encodeURIComponent('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 234 223"><path fill="'+rgb(accent)+'" fill-rule="evenodd" d="M 12 154 L 183 50 L 190 57 L 83 206 L 74 206 L 12 161 Z M 61 146 L 163 73 L 168 76 L 106 146 Z"/><path fill="#ffffff" d="M 207 17 L 222 32 L 207 47 L 192 32 Z"/></svg>')
    sourceSize.width: Math.ceil(width*2)
    sourceSize.height: Math.ceil(height*2)
    fillMode: Image.PreserveAspectFit
    smooth: true
}
