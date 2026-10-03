import QtQuick 2.5
Item {
    id: frame
    property url source
    property var crop: ({x:50,y:50,zoom:100})
    clip:true
    Image {
        id:image
        property real ratio: implicitHeight>0 ? implicitWidth/implicitHeight : 1
        width:Math.max(frame.width,frame.height*ratio)*(frame.crop.zoom/100)
        height:width/ratio
        x:(frame.width-width)*(frame.crop.x/100);y:(frame.height-height)*(frame.crop.y/100)
        source:frame.source;asynchronous:true;smooth:true;mipmap:true
    }
}
