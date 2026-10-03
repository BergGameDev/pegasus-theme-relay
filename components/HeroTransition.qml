import QtQuick 2.8
import QtQuick.Window 2.2
import QtGraphicalEffects 1.0
Item {
    id: stage
    objectName: "relayHero"
    signal transitionStarted()
    property color accent:"#8fcdaa"
    property url source
    property var options
    property real horizontalPosition: 0
    property real progress: 1
    property real seed: 0
    property int direction: 1
    property real previousPosition: 0
    property bool shaderFailed: false
    readonly property int graphicsApi: GraphicsInfo.api
    readonly property bool useShader: GraphicsInfo.api === GraphicsInfo.OpenGL && !shaderFailed
    readonly property int estimatedTriangles: Math.ceil(width/options.triangleSize)*Math.ceil(height/options.triangleSize)*2
    readonly property int transitionDuration: options.transitionMode===3 ? options.frostRevealMs+options.frostHoldMs+options.frostSharpMs : options.transitionMode===4 ? options.wipeMs : options.transitionMode===5 ? options.decodeMs : options.transitionMode===6 ? options.fractureMs : options.transitionMode===7 ? options.weaveMs : options.transitionMs
    readonly property bool transitioning: reveal.running
    readonly property bool neonActive: useShader && progress>0.001 && progress<0.999 && (options.transitionMode===5 || options.transitionMode===7)
    clip: true
    function requestImage(url) {
        restorePreview.stop(); reveal.stop();
        if (!String(url)) { outgoing.source=""; incoming.source=""; progress=1; return; }
        if (incoming.status===Image.Ready) outgoing.source=incoming.source;
        progress=0; seed=Math.random()*1000;
        if (String(incoming.source)===String(url)) begin(); else incoming.source=url;
    }
    function begin() {
        if(incoming.status!==Image.Ready) return;
        if (!String(outgoing.source) || !options.animation || options.transitionMode===2) progress=1;
        else { progress=0; reveal.restart();transitionStarted(); }
    }
    function replay(other) {
        requestImage(other || source);
        restorePreview.interval=transitionDuration+300; restorePreview.restart();
    }
    onSourceChanged: requestImage(source)
    onHorizontalPositionChanged: { direction=horizontalPosition>=previousPosition ? 1 : -1; previousPosition=horizontalPosition; }
    Connections {
        target: stage
        onOptionsChanged: { if (!stage.options.animation || stage.options.transitionMode===2) { reveal.stop(); stage.progress=1; } }
    }
    NumberAnimation { id: reveal; objectName: "relayHeroReveal"; target: stage; property: "progress"; from: 0; to: 1; duration: stage.transitionDuration; easing.type: Easing.Linear }
    Timer { id: restorePreview; onTriggered: stage.requestImage(stage.source) }
    Item {
        id: surface
        width: parent.width+stage.options.parallaxDepth*2; height: parent.height+stage.options.parallaxDepth*2
        x: -stage.options.parallaxDepth + (stage.options.animation ? stage.horizontalPosition*stage.options.parallaxDepth : 0)
        y: -stage.options.parallaxDepth
        Behavior on x { NumberAnimation { duration: stage.options.animation ? stage.options.motionMs*2 : 0; easing.type: Easing.OutCubic } }
        Image { id: outgoing; anchors.fill: parent; asynchronous: true; smooth: true; sourceSize.width: Math.ceil(width*Screen.devicePixelRatio); sourceSize.height: Math.ceil(height*Screen.devicePixelRatio); fillMode: Image.PreserveAspectCrop }
        Image {
            id: incoming; anchors.fill: parent; asynchronous: true; smooth: true
            sourceSize.width: Math.ceil(width*Screen.devicePixelRatio); sourceSize.height: Math.ceil(height*Screen.devicePixelRatio); fillMode: Image.PreserveAspectCrop
            opacity: stage.useShader ? 1 : stage.progress
            onStatusChanged: if(status===Image.Ready) stage.begin(); else if(status===Image.Error) { reveal.stop(); stage.progress=0; }
        }
        ShaderEffectSource { id: oldTexture; sourceItem: outgoing; hideSource: stage.useShader; live: true; visible: false }
        ShaderEffectSource { id: newTexture; sourceItem: incoming; hideSource: stage.useShader; live: true; visible: false }
        ShaderEffect {
            id: effect; onStatusChanged: if(status===ShaderEffect.Error && log.length>0) stage.shaderFailed=true
            objectName: "relayHeroShader"; anchors.fill: parent; visible: stage.useShader
            property variant previousTex: oldTexture
            property variant nextTex: newTexture
            property real phase: stage.progress
            property real randomSeed: stage.seed
            property real cellSize: stage.options.triangleSize
            property size resolution: Qt.size(width,height)
            property real sweepDirection: stage.direction
            property real prism: stage.options.prismStrength/100
            property real edgeStrength: stage.options.plexusEdges/100
            property real fadeLength: (stage.options.plexusFade || 45)/100
            property real meshMotion: (stage.options.plexusMotion || 0)/100
            property real colourSplit: (stage.options.prismSplit || 0)/100
            property color edgeTint:stage.accent
            property real triangleMode: stage.options.transitionMode===0 || stage.options.transitionMode===3 ? 1 : 0
            property real frostedMode:stage.options.transitionMode===3 ? 1:0
            property real blurRadius:stage.options.frostBlur || 0
            property real revealFraction:(stage.options.frostRevealMs || 1400)/Math.max(1,stage.transitionDuration)
            property real holdFraction:(stage.options.frostHoldMs || 0)/Math.max(1,stage.transitionDuration)
            property real flashScatter:(stage.options.frostScatter || 0)/100
            property real glintWidth:(stage.options.frostGlintWidth || 28)/100
            property real glintLength:Math.min(0.4,(stage.options.frostGlintMs || 80)/Math.max(1,stage.options.frostSharpMs || 800))
            property real glintTint:(stage.options.glintTint===undefined ? 85:stage.options.glintTint)/100
            property real flashStrength:(stage.options.frostFlash || 0)/100
            property real splitDistance:stage.options.prismDistance===undefined ? 12:stage.options.prismDistance
            property real splitAngle:(stage.options.prismAngle || 0)*Math.PI/180
            property real wipeMode:stage.options.transitionMode===4 ? 1:0
            property real wipeAngle:(stage.options.wipeAngle || 0)*Math.PI/180
            property real wipeSoftness:stage.options.wipeSoftness || 0
            property real wipeDirection:(stage.options.wipeReverse ? -1:1)*(stage.options.wipeFollow ? stage.direction:1)
            property real extraMode:stage.options.transitionMode
            property real pixelRatio:Screen.devicePixelRatio
            property real decodeViewportHeight:stage.height
            property point decodeOrigin:Qt.point(surface.x,surface.y)
            property real decodeMs:stage.options.decodeMs===undefined ? 1150:stage.options.decodeMs
            property real decodeCell:stage.options.decodeCell===undefined ? 10:stage.options.decodeCell
            property real decodeScatter:stage.options.decodeScatter===undefined ? 35:stage.options.decodeScatter
            property real decodeHold:stage.options.decodeHold===undefined ? 45:stage.options.decodeHold
            property real decodeGlow:stage.options.decodeGlow===undefined ? 60:stage.options.decodeGlow
            property real fractureMs:stage.options.fractureMs===undefined ? 1200:stage.options.fractureMs
            property real fractureSize:stage.options.fractureSize===undefined ? 180:stage.options.fractureSize
            property real fractureDepth:stage.options.fractureDepth===undefined ? 18:stage.options.fractureDepth
            property real fractureTilt:stage.options.fractureTilt===undefined ? 6:stage.options.fractureTilt
            property real fractureScatter:stage.options.fractureScatter===undefined ? 50:stage.options.fractureScatter
            property real fractureGlints:stage.options.fractureGlints===undefined ? 55:stage.options.fractureGlints
            property real weaveMs:stage.options.weaveMs===undefined ? 1100:stage.options.weaveMs
            property real weaveWidth:stage.options.weaveWidth===undefined ? 28:stage.options.weaveWidth
            property real weaveBend:stage.options.weaveBend===undefined ? 12:stage.options.weaveBend
            property real weaveAngle:stage.options.weaveAngle===undefined ? 0:stage.options.weaveAngle
            property real weaveStagger:stage.options.weaveStagger===undefined ? 40:stage.options.weaveStagger
            property real weaveGlow:stage.options.weaveGlow===undefined ? 45:stage.options.weaveGlow
            property real weaveContours:stage.options.weaveContours===undefined ? 30:stage.options.weaveContours
            property real decodeAngle:(stage.options.decodeAngle || 0)*Math.PI/180
            property real decodeSoftness:stage.options.decodeSoftness || 0
            property real decodeDirection:(stage.options.decodeReverse ? -1:1)*(stage.options.decodeFollow===false ? 1:stage.direction)
            property real decodeAnimate:stage.options.decodeAnimate===false ? 0:1
            property real decodeCharacterMs:stage.options.decodeCharacterMs===undefined ? 100:stage.options.decodeCharacterMs
            property real fractureReady:shardLoader.item && shardLoader.item.geometryReady ? 1:0
            property real glowPass: 0
            fragmentShader: "
                varying highp vec2 qt_TexCoord0;
                uniform sampler2D previousTex;
                uniform sampler2D nextTex;
                uniform lowp float qt_Opacity;
                uniform highp float fractureReady;
                uniform highp float glowPass;
                uniform highp float phase;
                uniform highp float randomSeed;
                uniform highp float cellSize;
                uniform highp vec2 resolution;
                uniform highp float sweepDirection;
                uniform highp float prism;
                uniform highp float triangleMode;
                uniform highp float edgeStrength;
                uniform lowp vec4 edgeTint;
                uniform highp float fadeLength;
                uniform highp float meshMotion;
                uniform highp float colourSplit;
                uniform highp float frostedMode;
                uniform highp float blurRadius;
                uniform highp float revealFraction;
                uniform highp float holdFraction;
                uniform highp float flashStrength;
                uniform highp float glintTint;
                uniform highp float flashScatter;
                uniform highp float glintWidth;
                uniform highp float glintLength;
                uniform highp float splitDistance;
                uniform highp float splitAngle;
                uniform highp float wipeMode;
                uniform highp float wipeAngle;
                uniform highp float wipeSoftness;
                uniform highp float wipeDirection;
                uniform highp float extraMode;
                uniform highp float pixelRatio;uniform highp float decodeViewportHeight;uniform highp vec2 decodeOrigin;
                uniform highp float decodeMs;
                uniform highp float decodeCell;
                uniform highp float decodeScatter;
                uniform highp float decodeHold;
                uniform highp float decodeGlow;
                uniform highp float decodeAngle;
                uniform highp float decodeSoftness;
                uniform highp float decodeDirection;
                uniform highp float decodeAnimate;
                uniform highp float decodeCharacterMs;
                uniform highp float fractureMs;
                uniform highp float fractureSize;
                uniform highp float fractureDepth;
                uniform highp float fractureTilt;
                uniform highp float fractureScatter;
                uniform highp float fractureGlints;
                uniform highp float weaveMs;
                uniform highp float weaveWidth;
                uniform highp float weaveBend;
                uniform highp float weaveAngle;
                uniform highp float weaveStagger;
                uniform highp float weaveGlow;
                uniform highp float weaveContours;
                highp float hash(highp vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7))+randomSeed)*43758.5453); }
                highp vec2 vertex(highp vec2 p) {
                    highp vec2 jitter=vec2(hash(p+13.2),hash(p+71.6))-0.5;
                    highp float meshPhase=mix(phase,min(1.0,phase/max(0.001,revealFraction)),frostedMode);
                    highp vec2 drift=vec2(sin(meshPhase*3.14159+hash(p+41.0)*6.28),cos(meshPhase*3.14159+hash(p+59.0)*6.28));
                    return p+jitter*0.74+drift*0.10*meshMotion*sin(meshPhase*3.14159);
                }
                highp float lighting(highp vec2 a,highp vec2 b,highp vec2 c) {
                    highp vec2 center=(a+b+c)/3.0*cellSize/resolution;
                    highp vec3 ab=vec3((b-a)*cellSize/resolution,(hash(b+91.0)-hash(a+91.0))*0.065);
                    highp vec3 ac=vec3((c-a)*cellSize/resolution,(hash(c+91.0)-hash(a+91.0))*0.065);
                    highp vec3 normal=normalize(cross(ab,ac));if(normal.z<0.0) normal=-normal;
                    highp vec2 toLight=vec2(0.18,0.5)-center;
                    highp vec3 light=normalize(vec3(toLight,0.32));
                    highp float falloff=1.0/(1.0+dot(toLight,toLight)*3.0);
                    return (max(0.0,dot(normal,light))-0.55)*falloff;
                }
                highp float cross2(highp vec2 a,highp vec2 b) { return a.x*b.y-a.y*b.x; }
                highp vec3 bary(highp vec2 p,highp vec2 a,highp vec2 b,highp vec2 c) {
                    highp float det=cross2(b-a,c-a);
                    highp float v=cross2(p-a,c-a)/det;
                    highp float w=cross2(b-a,p-a)/det;
                    return vec3(1.0-v-w,v,w);
                }
                highp float edgeDistance(highp vec2 p,highp vec2 a,highp vec2 b) { return abs(cross2(b-a,p-a))/max(0.001,length(b-a)); }
                // Project blur taps into the current triangle: no samples cross its hard mask.
                highp vec2 insideUV(highp vec2 uv,highp vec2 a,highp vec2 b,highp vec2 c) {
                    highp vec3 weights=max(bary(uv*resolution/max(18.0,cellSize),a,b,c),vec3(0.0));
                    weights/=max(0.001,weights.x+weights.y+weights.z);
                    return clamp((a*weights.x+b*weights.y+c*weights.z)*max(18.0,cellSize)/resolution,0.0,1.0);
                }
                lowp vec4 facetBlur(highp vec2 uv,highp float radius,highp vec2 a,highp vec2 b,highp vec2 c) {
                    mediump vec4 sum=texture2D(nextTex,uv);
                    highp float total=1.0;
                    // Weighted disk taps avoid repeated-image ghosts from a sparse square kernel.
                    for(int i=0;i<16;i++) {
                        highp float portion=(float(i)+0.5)/16.0;
                        highp float angle=float(i)*2.399963;
                        highp vec2 delta=vec2(cos(angle),sin(angle))*sqrt(portion)*radius/resolution;
                        highp float weight=exp(-portion*3.0);
                        sum+=texture2D(nextTex,insideUV(uv+delta,a,b,c))*weight;total+=weight;
                    }
                    return sum/total;
                }

                highp float stroke(highp float distance,highp float halfWidth,highp float aa) {
                    return 1.0-smoothstep(max(0.0,halfWidth-aa),halfWidth+aa,distance);
                }
                highp float glyph(highp vec2 p,highp float ink) {
                    highp float kind=floor(clamp(ink,0.0,0.999)*8.0);
                    highp float x=p.x-.5,y=p.y-.5,aa=(glowPass>.5 ? 1.0:.5)/decodeCell;
                    highp float thin=max(.045,.45/decodeCell),dotWidth=max(.075,.50/decodeCell);
                    highp float dot0=stroke(abs(x),dotWidth,aa)*stroke(abs(y-.24),dotWidth,aa);
                    highp float dot1=stroke(abs(x),dotWidth,aa)*stroke(abs(y+.22),dotWidth,aa);
                    highp float h=stroke(abs(y),thin,aa)*stroke(abs(x),.34,aa);
                    highp float v=stroke(abs(x),thin,aa)*stroke(abs(y),.34,aa);
                    highp float slash=stroke(abs(x+y*.70),thin,aa)*stroke(abs(y),.36,aa);
                    highp float equals=stroke(abs(abs(y)-.15),thin,aa)*stroke(abs(x),.34,aa);
                    highp float rails=stroke(abs(abs(x)-.17),thin,aa)*stroke(abs(y),.34,aa);
                    if(kind<1.0)return dot0;if(kind<2.0)return max(dot0,dot1);if(kind<3.0)return h;
                    if(kind<4.0)return slash;if(kind<5.0)return max(h,v);if(kind<6.0)return equals;
                    if(kind<7.0)return max(equals,rails);return max(max(equals,rails),max(h,v));
                }
                highp float luma(lowp vec3 c) { return dot(c,vec3(0.2126,0.7152,0.0722)); }
                void main() {
                    highp vec2 uv=qt_TexCoord0;
                    if(glowPass>0.5 && (phase>=0.999 || phase<=0.001)) {gl_FragColor=vec4(0.0);return;}
                    if(phase>=0.999) { gl_FragColor=texture2D(nextTex,uv)*qt_Opacity;return; }
                    if(phase<=0.001) { gl_FragColor=texture2D(previousTex,uv)*qt_Opacity;return; }

                    if(extraMode>4.5 && extraMode<5.5) {
                        // Screen-locked glyphs avoid subpixel shimmer while the background parallax moves.
                        highp vec2 pixel=gl_FragCoord.xy*(glowPass>.5 ? 2.0:1.0/max(1.0,pixelRatio));
                        pixel.y=(glowPass>.5 ? resolution.y:decodeViewportHeight)-pixel.y;
                        if(glowPass>.5)pixel+=decodeOrigin;
                        highp vec2 cell=floor(pixel/decodeCell),fp=fract(pixel/decodeCell);
                        // Convert the stable screen-grid sample back into the moving artwork texture.
                        highp vec2 center=((cell+0.5)*decodeCell-decodeOrigin)/resolution;
                        lowp vec4 next=texture2D(nextTex,center);
                        highp float hold=decodeHold/100.0;
                        highp vec2 axis=vec2(cos(decodeAngle),sin(decodeAngle))*decodeDirection;
                        highp float extent=max(1.0,dot(abs(axis),resolution));
                        highp float position=dot((center-0.5)*resolution,axis)/extent+0.5;
                        highp float rank=mix(position,hash(floor(cell/3.0)+7.0),decodeScatter/100.0);
                        hold=min(0.95,hold+decodeSoftness/extent);
                        highp float t=clamp((phase-rank*(1.0-hold))/hold,0.0,1.0);
                        highp float intermediate=smoothstep(0.0,0.20,t)*(1.0-smoothstep(0.55,1.0,t));
                        highp float ink=luma(next.rgb);
                        highp float tick=floor(phase*decodeMs/max(30.0,decodeCharacterMs)+hash(cell+91.0)*3.0);
                        highp float animatedInk=clamp(ink+(hash(cell+vec2(tick,tick*7.0))-0.5)*0.36,0.0,0.999);
                        highp float g=glyph(fp,mix(ink,animatedInk,decodeAnimate));
                        highp float light=g*(0.32+luma(next.rgb)*1.15);
                        if(glowPass>0.5) {highp float e=light*intermediate*decodeGlow/100.0;gl_FragColor=vec4(edgeTint.rgb*e,e)*qt_Opacity;return;}
                        lowp vec4 terminal=vec4(mix(edgeTint.rgb,vec3(1.0),0.82)*light,1.0);
                        lowp vec4 image=mix(texture2D(previousTex,uv),texture2D(nextTex,uv),smoothstep(0.15,0.95,t));
                        gl_FragColor=mix(image,terminal,intermediate)*qt_Opacity;return;
                    }
                    if(extraMode>5.5 && extraMode<6.5) {
                        gl_FragColor=mix(texture2D(previousTex,uv),texture2D(nextTex,uv),fractureReady)*qt_Opacity;return;
                    }
                    if(extraMode>6.5) {
                        highp float a=weaveAngle*0.0174533;
                        highp vec2 xy=(uv-0.5)*resolution;
                        highp vec2 q=vec2(cos(a)*xy.x+sin(a)*xy.y,-sin(a)*xy.x+cos(a)*xy.y);
                        highp float extent=dot(abs(vec2(cos(a),sin(a))),resolution);
                        highp vec2 grid=floor(q/weaveWidth),local=fract(q/weaveWidth);
                        highp float row=grid.y;
                        highp float random=hash(vec2(row,21.0));
                        highp float stagger=weaveStagger/100.0*0.26;
                        highp float position=q.x/extent+0.5;
                        position=mix(position,1.0-position,step(sweepDirection,0.0));
                        highp float boundary=phase*(1.0+2.0*stagger)-stagger+(random-0.5)*stagger*1.8;
                        highp float horizontal=1.0-smoothstep(boundary-0.002,boundary+0.002,position);
                        highp float front=1.0-smoothstep(0.015,0.22,abs(position-boundary));
                        // Only parallel ribbon seams emit light.
                        highp float over=step(0.5,mod(row,2.0));
                        highp float mask=horizontal;
                        highp float motion=sin(phase*3.14159)*front;
                        highp vec2 shift=vec2(cos(a),sin(a))*sin(row*0.7+phase*3.14159)*weaveBend/resolution*motion;
                        lowp vec4 col=mix(texture2D(previousTex,clamp(uv-shift,0.0,1.0)),texture2D(nextTex,clamp(uv+shift,0.0,1.0)),mask);
                        highp float seam=min(local.y,1.0-local.y)*weaveWidth;
                        highp float aa=max(0.65,0.65*(abs(cos(a))+abs(sin(a))))*(glowPass>0.5 ? 2.0:1.0/max(1.0,pixelRatio));
                        highp float thread=(1.0-smoothstep(0.0,1.1+aa,seam))*(0.12+front*0.88);
                        // Blend the neighbouring ribbon only within the seam footprint; no full-screen blur.
                        highp float adjacent=row+(local.y<0.5 ? -1.0:1.0);
                        highp float nextBoundary=phase*(1.0+2.0*stagger)-stagger+(hash(vec2(adjacent,21.0))-0.5)*stagger*1.8;
                        highp float nextMask=1.0-smoothstep(nextBoundary-0.002,nextBoundary+0.002,position);
                        highp float nextMotion=sin(phase*3.14159)*(1.0-smoothstep(0.015,0.22,abs(position-nextBoundary)));
                        highp vec2 nextShift=vec2(cos(a),sin(a))*sin(adjacent*0.7+phase*3.14159)*weaveBend/resolution*nextMotion;
                        lowp vec4 adjacentColor=mix(texture2D(previousTex,clamp(uv-nextShift,0.0,1.0)),texture2D(nextTex,clamp(uv+nextShift,0.0,1.0)),nextMask);
                        col=mix(col,adjacentColor,0.5*(1.0-smoothstep(0.0,aa,seam)));
                        lowp vec3 center=texture2D(nextTex,uv).rgb;
                        highp float contour=abs(luma(texture2D(nextTex,clamp(uv+vec2(1.8,0.0)/resolution,0.0,1.0)).rgb)-luma(center))+abs(luma(texture2D(nextTex,clamp(uv+vec2(0.0,1.8)/resolution,0.0,1.0)).rgb)-luma(center));
                        highp float active=sin(phase*3.14159);
                        col.rgb*=1.0+(over-0.5)*0.08*motion;
                        highp float emission=thread*weaveGlow/100.0*active+contour*weaveContours/100.0*motion;
                        if(glowPass>0.5) {gl_FragColor=vec4(edgeTint.rgb*emission,emission)*qt_Opacity;return;}
                        col.rgb+=mix(edgeTint.rgb,vec3(1.0),0.85)*emission*0.85;
                        gl_FragColor=col*qt_Opacity;return;
                    }
                    if(wipeMode>0.5) {
                        highp vec2 axis=vec2(cos(wipeAngle),sin(wipeAngle))*wipeDirection;
                        highp float extent=max(1.0,dot(abs(axis),resolution));
                        highp float position=dot((uv-0.5)*resolution,axis)+extent*0.5;
                        highp float boundary=mix(-wipeSoftness,extent+wipeSoftness,phase);
                        highp float amount=wipeSoftness<0.5 ? 1.0-step(boundary,position) : 1.0-smoothstep(boundary-wipeSoftness,boundary+wipeSoftness,position);
                        gl_FragColor=mix(texture2D(previousTex,uv),texture2D(nextTex,uv),amount)*qt_Opacity;return;
                    }
                    if(triangleMode<0.5) { gl_FragColor=mix(texture2D(previousTex,uv),texture2D(nextTex,uv),phase)*qt_Opacity;return; }
                    highp vec2 p=uv*resolution/max(18.0,cellSize);
                    highp vec2 home=floor(p);
                    highp float random=0.5;
                    highp float distance=1.0;
                    highp float found=0.0;
                    highp float illumination=0.0;
                    highp vec2 facetA=home,facetB=home+vec2(1.0,0.0),facetC=home+vec2(0.0,1.0);
                    for(int iy=-1;iy<=1;iy++) {
                        for(int ix=-1;ix<=1;ix++) {
                            highp vec2 cell=home+vec2(float(ix),float(iy));
                            highp vec2 a=vertex(cell),b=vertex(cell+vec2(1.0,0.0)),c=vertex(cell+vec2(1.0,1.0)),d=vertex(cell+vec2(0.0,1.0));
                            highp float flip=step(0.5,hash(cell+125.0));
                            highp vec2 t0=a,t1=b,t2=mix(c,d,flip);
                            highp vec3 w=bary(p,t0,t1,t2);
                            if(min(w.x,min(w.y,w.z))>=-0.0001 && found<0.5) {
                                random=hash(cell+17.0);distance=min(edgeDistance(p,t0,t1),min(edgeDistance(p,t1,t2),edgeDistance(p,t2,t0)));illumination=lighting(t0,t1,t2);facetA=t0;facetB=t1;facetC=t2;found=1.0;
                            }
                            t0=mix(a,b,flip);t1=c;t2=d;w=bary(p,t0,t1,t2);
                            if(min(w.x,min(w.y,w.z))>=-0.0001 && found<0.5) {
                                random=hash(cell+31.0);distance=min(edgeDistance(p,t0,t1),min(edgeDistance(p,t1,t2),edgeDistance(p,t2,t0)));illumination=lighting(t0,t1,t2);facetA=t0;facetB=t1;facetC=t2;found=1.0;
                            }
                        }
                    }
                    highp float sweep=mix(1.0-uv.x,uv.x,step(0.0,sweepDirection));
                    highp float span=clamp(fadeLength,0.15,0.70);
                    highp float threshold=(random*0.78+sweep*0.22)*(1.0-span);
                    highp float fadePhase=mix(phase,min(1.0,phase/max(0.001,revealFraction)),frostedMode);
                    highp float reveal=smoothstep(threshold,threshold+span,fadePhase);
                    highp float wave=clamp((phase-revealFraction-holdFraction)/max(0.001,1.0-revealFraction-holdFraction),0.0,1.0);
                    // Distance schedules discrete facet events; it never masks individual pixels.
                    highp float eventStart=random*0.82;
                    highp float localEvent=clamp((wave-eventStart)/0.18,0.0,1.0);
                    highp float sharpen=smoothstep(0.0,1.0,localEvent);
                    if(phase<=0.001) reveal=0.0;
                    if(phase>=0.999) reveal=1.0;
                    lowp vec4 nextColor=texture2D(nextTex,uv);
                    if(frostedMode>0.5 && blurRadius*(1.0-sharpen)>0.1 && reveal>0.001) nextColor=facetBlur(uv,blurRadius*(1.0-sharpen),facetA,facetB,facetC);
                    lowp vec4 col=mix(texture2D(previousTex,uv),nextColor,reveal);
                    highp float transition=sin(clamp(phase,0.0,1.0)*3.14159)*triangleMode;
                    highp float facet=mix(sin(reveal*3.14159)*transition,max(sin(reveal*3.14159),sin(sharpen*3.14159)),frostedMode);
                    col.rgb*=1.0+illumination*0.65*prism*facet;
                    if(colourSplit>0.001 && facet>0.001) {
                    highp vec2 offset=vec2(cos(splitAngle+random*0.5),sin(splitAngle+random*0.5))*splitDistance/resolution*colourSplit*facet;
                    lowp vec4 shifted=mix(texture2D(previousTex,clamp(uv+offset,0.0,1.0)),texture2D(nextTex,clamp(uv+offset,0.0,1.0)),reveal);
                    lowp vec4 opposite=mix(texture2D(previousTex,clamp(uv-offset,0.0,1.0)),texture2D(nextTex,clamp(uv-offset,0.0,1.0)),reveal);
                    col.r=mix(col.r,shifted.r,colourSplit*facet);
                    col.g=mix(col.g,opposite.g,colourSplit*facet);
                    }
                    highp float stroke=(1.0-smoothstep(0.25,1.1,distance*cellSize))*edgeStrength*transition;
                    col.rgb=mix(col.rgb,edgeTint.rgb*col.a,stroke*0.28);

                    gl_FragColor=col*qt_Opacity;
                }"

        }
        Loader {
            id:shardLoader
            objectName:"relayShardLoader"
            active: stage.useShader && stage.options.transitionMode===6 && stage.progress>0.001 && stage.progress<0.999
            anchors.fill: parent
            sourceComponent: Component { ShardTransition { onFailed:stage.shaderFailed=true; nextTexture:newTexture; sourceTexture:oldTexture; progress:stage.progress; randomSeed:stage.seed; options:stage.options; accent:stage.accent; direction:stage.direction } }
        }
        ShaderEffect {
            id: emission; anchors.fill: parent; visible:false
            property variant previousTex: effect.previousTex
            property variant nextTex: effect.nextTex
            property real phase: effect.phase
            property real randomSeed: effect.randomSeed
            property real cellSize: effect.cellSize
            property size resolution: effect.resolution
            property real sweepDirection: effect.sweepDirection
            property real prism: effect.prism
            property real edgeStrength: effect.edgeStrength
            property real fadeLength: effect.fadeLength
            property real meshMotion: effect.meshMotion
            property real colourSplit: effect.colourSplit
            property color edgeTint: effect.edgeTint
            property real triangleMode: effect.triangleMode
            property real frostedMode: effect.frostedMode
            property real blurRadius: effect.blurRadius
            property real revealFraction: effect.revealFraction
            property real holdFraction: effect.holdFraction
            property real flashScatter: effect.flashScatter
            property real glintWidth: effect.glintWidth
            property real glintLength: effect.glintLength
            property real glintTint: effect.glintTint
            property real flashStrength: effect.flashStrength
            property real splitDistance: effect.splitDistance
            property real splitAngle: effect.splitAngle
            property real wipeMode: effect.wipeMode
            property real wipeAngle: effect.wipeAngle
            property real wipeSoftness: effect.wipeSoftness
            property real wipeDirection: effect.wipeDirection
            property real extraMode: effect.extraMode
            property real pixelRatio:effect.pixelRatio
            property real decodeViewportHeight:effect.decodeViewportHeight
            property point decodeOrigin:effect.decodeOrigin
            property real decodeMs: effect.decodeMs
            property real decodeCell: effect.decodeCell
            property real decodeScatter: effect.decodeScatter
            property real decodeHold: effect.decodeHold
            property real decodeGlow: effect.decodeGlow
            property real fractureMs: effect.fractureMs
            property real fractureSize: effect.fractureSize
            property real fractureDepth: effect.fractureDepth
            property real fractureTilt: effect.fractureTilt
            property real fractureScatter: effect.fractureScatter
            property real fractureGlints: effect.fractureGlints
            property real weaveMs: effect.weaveMs
            property real weaveWidth: effect.weaveWidth
            property real weaveBend: effect.weaveBend
            property real weaveAngle: effect.weaveAngle
            property real weaveStagger: effect.weaveStagger
            property real weaveGlow: effect.weaveGlow
            property real weaveContours: effect.weaveContours
            property real decodeAngle:effect.decodeAngle
            property real decodeSoftness:effect.decodeSoftness
            property real decodeDirection:effect.decodeDirection
            property real decodeAnimate:effect.decodeAnimate
            property real decodeCharacterMs:effect.decodeCharacterMs
            property real fractureReady:effect.fractureReady
            property real glowPass: 1
            fragmentShader:effect.fragmentShader
            onStatusChanged: if(status===ShaderEffect.Error) console.warn("Neon emission shader:",log)
        }
        ShaderEffectSource { id: lightTexture; sourceItem:emission; hideSource:true; live:stage.neonActive; visible:false; textureSize:Qt.size(Math.ceil(surface.width/2),Math.ceil(surface.height/2)) }
        FastBlur { id: haloBlur; width:parent.width/Math.max(1,requestedRadius/64);height:parent.height/Math.max(1,requestedRadius/64);property real requestedRadius:(stage.options[stage.options.transitionMode===5 ? "decodeHaloRadius":"weaveHaloRadius"]===undefined ? (stage.options.glowRadius===undefined ? 32:stage.options.glowRadius):stage.options[stage.options.transitionMode===5 ? "decodeHaloRadius":"weaveHaloRadius"]); source:lightTexture;radius:Math.min(64,requestedRadius);transparentBorder:true;cached:false;visible:false }
        ShaderEffectSource { id: haloTexture; sourceItem:haloBlur; hideSource:true; live:stage.neonActive; visible:false; textureSize:Qt.size(Math.ceil(surface.width/2),Math.ceil(surface.height/2)) }
        ShaderEffect {
            anchors.fill:parent; visible:stage.neonActive
            property variant source:haloTexture
            property real strength:(stage.options[stage.options.transitionMode===5 ? "decodeBloomIntensity":"weaveBloomIntensity"]===undefined ? (stage.options.glowIntensity===undefined ? 100:stage.options.glowIntensity):stage.options[stage.options.transitionMode===5 ? "decodeBloomIntensity":"weaveBloomIntensity"])/100*3.0
            fragmentShader:"varying highp vec2 qt_TexCoord0; uniform sampler2D source; uniform lowp float qt_Opacity; uniform highp float strength; void main(){lowp vec4 c=texture2D(source,qt_TexCoord0);gl_FragColor=vec4(c.rgb*strength*qt_Opacity,0.0);}"
        }

    }
}
