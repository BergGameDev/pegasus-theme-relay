import QtQuick 2.5
Item {
    id:field;property var options;property color accent;property real clock:0;property real gust:0
    property string populationKey:[options.particlePlacement,options.particleDensityBias,options.particleEdgeBias,options.particleTop,options.particleBottom,options.particleLeft,options.particleRight].join(":")
    onPopulationKeyChanged: { for(var i=0;i<pool.count;i++) {var item=pool.itemAt(i);if(item) item.renew(false);} }
    objectName:"relayParticles"
    // Visual-only bounded pool. No input handlers; particles never intercept controls.
    clip:true;visible:options.particleCount>0 && options.particleOpacity>0
    function random(n) { var v=Math.sin(n*127.1+31.7)*43758.5453;return v-Math.floor(v); }
    function sway(direction) { if(options.animation) gust+=direction*options.particleWind/100*90; }
    function inRegion(x,y) {
        if(options.particlePlacement===0) return y>=height*0.70 && y<=height;
        if(options.particlePlacement===2) return x<width*0.18 || x>width*0.82 || y<height*0.18 || y>height*0.82;
        return true;
    }
    function spawn(n) {
        var px=width/2,py=height*.85;
        var biased=options.particlePlacement===1 && options.particleDensityBias;
        var weights=biased ? [options.particleTop,options.particleBottom,options.particleLeft,options.particleRight]:[100,100,100,100];
        var total=weights[0]+weights[1]+weights[2]+weights[3];
        if(total<=0) return {x:px,y:py,enabled:false};
        for(var attempt=0;attempt<80;attempt++) {
            var a=n+attempt*7;
            px=random(a+1)*width;py=random(a+2)*height;
            if(!inRegion(px,py)) continue;
            // Each side gets its own population weight; proximity decides the side.
            var distances=[py/height,1-py/height,px/width,1-px/width];
            var side=0;for(var j=1;j<4;j++) if(distances[j]<distances[side]) side=j;
            var edge=1-Math.min(1,Math.min(px/width,1-px/width,py/height,1-py/height)*2);
            var bias=biased ? options.particleEdgeBias/100:0;
            var acceptance=(weights[side]/200)*((1-bias)+bias*Math.pow(edge,6));
            if(random(a+3)<acceptance) return {x:px,y:py,enabled:true};
        }
        // Deterministic valid fallback on an enabled edge (never the excluded center).
        var best=0;for(var k=1;k<4;k++) if(weights[k]>weights[best]) best=k;
        if(options.particlePlacement===0) return {x:random(n+5)*width,y:height*.98,enabled:true};
        return {x:best===2 ? width*.02:best===3 ? width*.98:random(n+4)*width,y:best===0 ? height*.02:best===1 ? height*.98:random(n+5)*height,enabled:true};
    }
    Timer {
        interval:33;repeat:true;running:field.visible && field.options.animation
        onTriggered:{
            field.clock+=0.033;field.gust*=Math.exp(-0.033*3);
            for(var i=0;i<pool.count;i++) {var item=pool.itemAt(i);if(item) item.advance(0.033);}
        }
    }
    Repeater {
        id:pool;model:field.options.particleCount
        Rectangle {
            id:pixel;objectName:"relayParticle"
            property int generation:0
            property real age:0
            property real lifetime:45
            property real velocityX:0
            property real velocityY:0
            property real variety:field.random(index+19)
            property bool spawned:false
            property real edgePresence:Math.min(1,Math.max(Math.abs(x/Math.max(1,field.width)-0.5),Math.abs(y/Math.max(1,field.height)-0.5))*2)
            property real shine:Math.pow(Math.max(0,Math.sin(field.clock*1.5+field.random(index+113)*6.283)),48)*(field.options.particleGlint || 0)/100
            function renew(initial) {
                generation++;var n=index*137+generation*239;
                var point=field.spawn(n);x=point.x;y=point.y;spawned=point.enabled;
                lifetime=field.options.particleLifetime*(0.75+field.random(n+9)*0.5);
                age=initial ? lifetime*(0.1+field.random(n+10)*0.7):0;
                velocityX=(field.random(n+11)-0.5)*10;velocityY=-(2+field.random(n+12)*8);
                rotation=field.random(n+13)*360;
            }
            function advance(dt) {
                if(!spawned || !field.inRegion(x,y)) {renew(false);return;}
                age+=dt;
                var speed=field.options.particleSpeed/100;
                x+=(velocityX*speed+field.gust*(0.4+variety))*dt;
                y+=velocityY*speed*dt;rotation+=dt*(variety-0.5)*5*speed;
                if(age>=lifetime || x<-width || x>field.width || y<-height || y>field.height || !field.inRegion(x,y)) renew(false);
            }
            Component.onCompleted:renew(true)
            width:Math.max(1,field.options.particleSize*(1+(variety*2-1)*field.options.particleVariation/100));height:width
            property real tint:(field.options.glintTint===undefined ? 85:field.options.glintTint)/100
            color:Qt.rgba(Math.min(1,field.accent.r+shine*(field.accent.r*tint*0.6+(1-field.accent.r)*(1-tint))),Math.min(1,field.accent.g+shine*(field.accent.g*tint*0.6+(1-field.accent.g)*(1-tint))),Math.min(1,field.accent.b+shine*(field.accent.b*tint*0.6+(1-field.accent.b)*(1-tint))),1)
            opacity:spawned ? field.options.particleOpacity/100*(1-(field.options.particleCenterFade || 0)/100*(1-edgePresence))*Math.min(1,age/(lifetime*0.1),(lifetime-age)/(lifetime*0.1)):0
            Rectangle { anchors.centerIn:parent;width:parent.width*3;height:width;radius:width/2;color:field.accent;opacity:parent.shine*0.18;z:-1 }
        }
    }
}
