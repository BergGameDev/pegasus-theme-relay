import QtQuick 2.8
import QtGraphicalEffects 1.0
Item {
    id:shards
    signal failed()
    property variant nextTexture
    property variant sourceTexture
    property real progress:0
    property real randomSeed:0
    property var options
    property color accent
    property int direction:1
    readonly property int paneSize:options.fractureSize || 320
    readonly property real irregularity:(options.fractureRandomness===undefined ? 85:options.fractureRandomness)/100
    readonly property real splitFraction:(options.fractureSplit===undefined ? 20:options.fractureSplit)/100
    readonly property int childCount:options.fractureChildren===undefined ? 3:options.fractureChildren
    readonly property int pieceLimit:options.fractureLimit===undefined ? 128:options.fractureLimit
    readonly property real impactRadius:(options.fractureImpactRadius===undefined ? 45:options.fractureImpactRadius)/100
    readonly property real coreFraction:(options.fractureCoreSplit===undefined ? 40:options.fractureCoreSplit)/100
    property bool geometryReady:false
    // Built only when geometry inputs change. Animation is entirely in the vertex shaders.
    readonly property var cells:makeCells(width,height,paneSize,irregularity,randomSeed,splitFraction,childCount,pieceLimit,impactRadius,coreFraction)
    function random(key,seed){var v=Math.sin(key*127.1+seed*0.173)*43758.5453;return v-Math.floor(v);}
    function clipPolygon(poly,nx,ny,d){
        var out=[];
        for(var i=0;i<poly.length;i++){
            var a=poly[i],b=poly[(i+1)%poly.length],da=a.x*nx+a.y*ny-d,db=b.x*nx+b.y*ny-d;
            if(da<=0.0001) out.push(a);
            if((da<0)!==(db<0)){var t=da/(da-db);out.push({x:a.x+(b.x-a.x)*t,y:a.y+(b.y-a.y)*t});}
        }
        return out;
    }
    function makeCells(w,h,size,jitter,seed,split,children,limit,impact,core){
        limit=limit===undefined ? 128:Math.max(32,Math.min(128,limit));impact=impact===undefined ? .45:impact;core=core===undefined ? .40:core;
        if(w<=0 || h<=0) return [];
        var cols=Math.max(1,Math.ceil(w/size)),rows=Math.max(1,Math.ceil(h/size));
        while(cols*rows>(split>0 ? Math.max(8,Math.floor(limit*.5)):limit)){if(cols/w>rows/h && cols>1)cols--;else if(rows>1)rows--;else cols--;}
        var sites=[],cw=w/cols,ch=h/rows;
        for(var y=0;y<rows;y++)for(var x=0;x<cols;x++){
            var k=y*cols+x;sites.push({x:(x+0.5+(random(k*3+1,seed)-0.5)*0.96*jitter)*cw,y:(y+0.5+(random(k*3+2,seed)-0.5)*0.96*jitter)*ch,k:k});
        }
        var result=[];
        for(var i=0;i<sites.length;i++){
            var site=sites[i],poly=[{x:0,y:0},{x:w,y:0},{x:w,y:h},{x:0,y:h}];
            // All sites participate, so these are real clipped Voronoi cells, not jittered triangles.
            for(var j=0;j<sites.length && poly.length>=3;j++)if(i!==j){
                var other=sites[j],nx=other.x-site.x,ny=other.y-site.y,d=(other.x*other.x+other.y*other.y-site.x*site.x-site.y*site.y)/2;
                poly=clipPolygon(poly,nx,ny,d);
            }
            if(poly.length<3)continue;
            // Collinear/clipped duplicate points do not need mesh slots.
            var clean=[];
            for(var n=0;n<poly.length;n++){var a=poly[n],b=poly[(n+1)%poly.length];if(Math.abs(a.x-b.x)+Math.abs(a.y-b.y)>0.01)clean.push(a);}
            if(clean.length<3 || clean.length>12)continue;
            var radius=Math.min(cw,ch);
            for(var n=0;n<clean.length;n++){var a=clean[n],b=clean[(n+1)%clean.length],ex=b.x-a.x,ey=b.y-a.y;radius=Math.min(radius,Math.abs(ex*(site.y-a.y)-ey*(site.x-a.x))/Math.max(0.001,Math.sqrt(ex*ex+ey*ey)));}
            result.push({points:clean,center:site,random:random(site.k*11+7,seed),radius:radius});
        }
        function distance(c){var dx=(c.center.x-w*.5)/(w*.5),dy=(c.center.y-h*.5)/(h*.5);return Math.sqrt(dx*dx+dy*dy)/Math.sqrt(2);}
        function makeCell(points,center,rng,level){
            var radius=Math.max(w,h);
            for(var n=0;n<points.length;n++){var a=points[n],b=points[(n+1)%points.length],ex=b.x-a.x,ey=b.y-a.y;radius=Math.min(radius,Math.abs(ex*(center.y-a.y)-ey*(center.x-a.x))/Math.max(.001,Math.sqrt(ex*ex+ey*ey)));}
            return {points:points,center:center,parent:center,random:rng,radius:radius,secondary:level/2,childRandom:rng};
        }
        function divide(parent,count,key,level){
            var sites=[],out=[];
            for(var j=0;j<count;j++){var v=parent.points[Math.floor(j*parent.points.length/count)],f=.28+random(key+j*7+53,seed)*.4;sites.push({x:parent.center.x+(v.x-parent.center.x)*f,y:parent.center.y+(v.y-parent.center.y)*f});}
            for(var j=0;j<count;j++){
                var poly=parent.points.slice(),site=sites[j];
                for(var k=0;k<count;k++)if(k!==j){var a=sites[k];poly=clipPolygon(poly,a.x-site.x,a.y-site.y,(a.x*a.x+a.y*a.y-site.x*site.x-site.y*site.y)/2);}
                if(poly.length>=3 && poly.length<=12)out.push(makeCell(poly,site,random(key+j*11+853,seed),level));
            }
            return out.length===count ? out:[parent];
        }
        var parents=result;parents.sort(function(a,b){return distance(a)-distance(b);});
        result=[];var budget=limit-parents.length;
        for(var i=0;i<parents.length;i++){
            var parent=parents[i];parent.parent=parent.center;parent.secondary=0;parent.childRandom=parent.random;
            var d=distance(parent),eligible=d<impact && random(i*19+331,seed)<split;
            if(!eligible || budget<children-1){result.push(parent);continue;}
            var childrenCells=divide(parent,children,i*67+113,1);budget-=childrenCells.length-1;
            childrenCells.sort(function(a,b){return distance(a)-distance(b);});
            for(var j=0;j<childrenCells.length;j++){
                var child=childrenCells[j];
                if(budget>=2 && distance(child)<impact*.55 && random(i*79+j*13+19,seed)<core){
                    var fine=divide(child,3,i*139+j*29+457,2);budget-=fine.length-1;result=result.concat(fine);
                }else result.push(child);
            }
        }
        // Approximate painter ordering: retreating pieces first, approaching pieces last.
        result.sort(function(a,b){return a.random-b.random;});
        return result;
    }
    onCellsChanged:{geometryReady=false;if(geometryCanvas)geometryCanvas.requestPaint();}
    Canvas {
        id:geometryCanvas;width:36;height:Math.max(1,shards.cells.length);visible:false
        renderTarget:Canvas.Image
        Component.onCompleted:requestPaint()
        onPaint:{
            var ctx=getContext('2d');ctx.clearRect(0,0,width,height);
            function encode(x,y,row,slot){
                var a=Math.round(Math.max(0,Math.min(1,x))*65535),b=Math.round(Math.max(0,Math.min(1,y))*65535);
                ctx.fillStyle='rgb('+Math.floor(a/256)+','+(a%256)+','+Math.floor(b/256)+')';ctx.fillRect(slot*2,row,1,1);
                ctx.fillStyle='rgb('+(b%256)+',0,0)';ctx.fillRect(slot*2+1,row,1,1);
            }
            for(var i=0;i<shards.cells.length;i++){
                var c=shards.cells[i];
                for(var j=0;j<=12;j++){var v=c.points[j<c.points.length ? j:0];encode(v.x/shards.width,v.y/shards.height,i,j);}
                encode(c.center.x/shards.width,c.center.y/shards.height,i,13);
                encode(c.random,c.radius/Math.max(shards.width,shards.height),i,14);
                encode(c.points.length/12,c.secondary || 0,i,15);
                encode(c.parent.x/shards.width,c.parent.y/shards.height,i,16);
                encode(c.childRandom || 0,0,i,17);
            }
        }
        onPainted:{geometryTexture.scheduleUpdate();shards.geometryReady=true;}
    }
    ShaderEffectSource {id:geometryTexture;sourceItem:geometryCanvas;hideSource:true;live:false;visible:false;smooth:false;textureSize:Qt.size(36,Math.max(1,shards.cells.length))}
    Repeater {
        // One face mesh, plus one wall mesh only when thickness is enabled.
        model:shards.options.fractureThickness===0 ? 1:2
        ShaderEffect {
            id:paneShader
            objectName:'relayShardShader'
            width:shards.width;height:shards.height;visible:shards.geometryReady
            z:index===0 ? 1:0
            mesh:GridMesh {resolution:Qt.size(Math.max(1,shards.cells.length*15-1),1)}
            property real part:index
            property variant source:shards.sourceTexture
            property variant nextTex:shards.nextTexture
            property variant geometryTex:geometryTexture
            property real cellCount:shards.cells.length
            property real segments:Math.max(1,shards.cells.length*15-1)
            property size resolution:Qt.size(width,height)
            property real phase:shards.progress
            property real randomSeed:shards.randomSeed
            property real travel:shards.options.fractureTravel===undefined ? 420:shards.options.fractureTravel
            property real spin:(shards.options.fractureSpin===undefined ? 85:shards.options.fractureSpin)*Math.PI/180
            property real roll:(shards.options.fractureTilt || 0)*Math.PI/180
            property real scatter:(shards.options.fractureScatter || 0)/100
            property real direction:shards.direction
            property real glints:(shards.options.fractureGlints || 0)/100
            property color accent:shards.accent
            property real refraction:shards.options.fractureDepth || 0
            property real glassOpacity:(shards.options.fractureOpacity===undefined ? 45:shards.options.fractureOpacity)/100
            property real reflection:(shards.options.fractureReflection===undefined ? 85:shards.options.fractureReflection)/100
            property real thickness:shards.options.fractureThickness===undefined ? 8:shards.options.fractureThickness
            property real separation:(shards.options.fractureSeparation===undefined ? 45:shards.options.fractureSeparation)/100
            property real specular:(shards.options.fractureSpecular===undefined ? 100:shards.options.fractureSpecular)/100
            property real glintWidth:(shards.options.fractureGlintWidth===undefined ? 18:shards.options.fractureGlintWidth)/100
            property real glintDuration:(shards.options.fractureGlintDuration===undefined ? 80:shards.options.fractureGlintDuration)/Math.max(200,shards.options.fractureMs || 1200)
            property real bevel:shards.options.fractureBevel===undefined ? 3:shards.options.fractureBevel
            vertexShader:"
                uniform highp mat4 qt_Matrix;
                attribute highp vec4 qt_Vertex;
                uniform sampler2D geometryTex;
                uniform highp float part;uniform highp float thickness;uniform highp float phase;uniform highp float randomSeed;uniform highp float cellCount;uniform highp float segments;uniform highp float travel;uniform highp float spin;uniform highp float roll;uniform highp float scatter;uniform highp float direction;
                uniform highp vec2 resolution;uniform highp float separation;
                varying highp vec2 uv,local;varying highp float edgeDistance,lane;varying highp float fade,shine;
                varying highp vec3 normal;varying highp vec2 screenUv;varying highp float material,paneSeed,paneTime,splitStage,secondaryPane;
                highp vec2 data(highp float row,highp float slot){
                    highp vec4 a=texture2D(geometryTex,vec2((slot*2.0+0.5)/36.0,(row+0.5)/cellCount));
                    highp vec4 b=texture2D(geometryTex,vec2((slot*2.0+1.5)/36.0,(row+0.5)/cellCount));
                    return vec2(a.r*65280.0+a.g*255.0,a.b*65280.0+b.r*255.0)/65535.0;
                }
                highp float hash(highp vec2 p){return fract(sin(dot(p,vec2(127.1,311.7))+randomSeed)*43758.5453);}
                void main(){
                    lane=floor(qt_Vertex.x/resolution.x*segments+0.5);
                    highp float row=floor(lane/15.0),slot=mod(lane,15.0),bottom=step(0.5,qt_Vertex.y/resolution.y);
                    highp vec2 center=data(row,13.0)*resolution,pivot=data(row,16.0)*resolution,info=data(row,14.0);
                    highp vec2 meta=data(row,15.0);highp float count=floor(meta.x*12.0+0.5);highp float childSeed=data(row,17.0).x;
                    highp float vertex=max(0.0,slot-1.0);
                    highp vec2 point=data(row,vertex)*resolution;
                    highp vec2 p=center;highp float extrusion=0.0;
                    normal=vec3(0.0,0.0,1.0);edgeDistance=info.y*max(resolution.x,resolution.y);
                    if(slot>0.5 && slot<13.5){
                        if(part<0.5){p=mix(center,point,bottom);edgeDistance*=1.0-bottom;}
                        else{
                            p=point;extrusion=-thickness*bottom*smoothstep(0.0,0.10,phase);
                            highp float next=mod(vertex+1.0,max(1.0,count));highp vec2 edge=data(row,next)*resolution-point;
                            normal=normalize(vec3(edge.y,-edge.x,0.0001));edgeDistance=0.0;
                        }
                    }
                    uv=p/resolution;local=(p-center)/max(1.0,info.y*max(resolution.x,resolution.y));
                    highp float h=info.x;
                    highp vec2 radial=(pivot-resolution*.5)/(resolution*.5);
                    highp float distanceFromImpact=length(radial)/1.414214;
                    highp float rank=clamp(distanceFromImpact+(h-.5)*scatter*.15,0.0,1.0);
                    highp float t=clamp((phase-rank*.55)/.45,0.0,1.0),move=t*t;
                    paneSeed=h;paneTime=t;secondaryPane=0.0;splitStage=1.0;
                    highp vec3 v=vec3(p-pivot,extrusion);
                    highp float ax=(hash(pivot+37.0)-0.5)*2.0*spin*move,ay=(h-0.5)*2.0*spin*move,az=(hash(pivot+62.0)-0.5)*2.0*roll*move;
                    v.yz=mat2(cos(ax),sin(ax),-sin(ax),cos(ax))*v.yz;
                    v.xz=mat2(cos(ay),sin(ay),-sin(ay),cos(ay))*v.xz;
                    v.xy=mat2(cos(az),sin(az),-sin(az),cos(az))*v.xy;
                    normal.yz=mat2(cos(ax),sin(ax),-sin(ax),cos(ax))*normal.yz;
                    normal.xz=mat2(cos(ay),sin(ay),-sin(ay),cos(ay))*normal.xz;
                    normal.xy=mat2(cos(az),sin(az),-sin(az),cos(az))*normal.xy;
                    material=smoothstep(0.0,0.16,t);
                    highp vec2 outward=normalize(pivot-resolution*.5+vec2(.01));
                    highp vec2 jitter=vec2(hash(pivot+141.0)-.5,hash(pivot+212.0)-.5)*separation*.65;
                    v.xy+=pivot-resolution*.5+(outward+jitter)*travel*move*(.45+h*.55);
                    highp float depthDirection=distanceFromImpact<.45 ? (.65+h*.35):(h-.5)*1.6;
                    v.z+=depthDirection*travel*move;
                    highp float camera=max(resolution.x,resolution.y)*1.4,w=max(camera*0.15,camera-v.z)/camera;
                    highp vec2 projected=v.xy/w+resolution*0.5;screenUv=projected/resolution;
                    gl_Position=(qt_Matrix*vec4(projected,qt_Vertex.z,1.0))*w;
                    fade=1.0-smoothstep(0.55,1.0,t);shine=sin(t*3.14159)*abs(sin(ax)+sin(ay))*0.45;
                }"
            fragmentShader:"
                uniform sampler2D source;uniform sampler2D nextTex;uniform lowp float qt_Opacity;
                uniform highp float specular;uniform highp float glintWidth;uniform highp float glintDuration;uniform highp float glints;uniform highp float refraction;uniform highp float glassOpacity;uniform highp float reflection;uniform highp float bevel;uniform highp float part;uniform highp vec2 resolution;uniform lowp vec4 accent;
                varying highp vec2 uv,local;varying highp float edgeDistance,lane;varying highp float fade,shine;
                varying highp vec3 normal;varying highp vec2 screenUv;varying highp float material,paneSeed,paneTime,splitStage,secondaryPane;
                void main(){
                    if(part>0.5 && (mod(floor(lane+0.0001),15.0)<1.0 || mod(floor(lane+0.0001),15.0)>12.0)) discard;
                    highp vec3 n=normalize(normal);
                    highp float grazing=pow(1.0-abs(n.z),2.0);
                    highp vec2 offset=n.xy*refraction/resolution*material;
                    lowp vec3 image=texture2D(source,clamp(uv+offset*0.25,0.0,1.0)).rgb;
                    lowp vec3 through=texture2D(nextTex,clamp(screenUv+offset,0.0,1.0)).rgb;
                    highp float edge=edgeDistance;
                    highp float rim=(1.0-smoothstep(0.2,max(0.3,bevel),edge))*mix(1.0,smoothstep(0.0,0.20,splitStage),secondaryPane);
                    highp vec3 light=normalize(vec3(-0.4,-0.25,0.9));
                    highp float facing=pow(max(0.0,abs(dot(n,normalize(light+vec3(0.0,0.0,1.0))))),8.0);
                    highp float angle=paneSeed*6.28318;
                    highp vec2 axis=vec2(cos(angle),sin(angle)),crossAxis=vec2(-axis.y,axis.x);
                    highp float pos=dot(local,axis),crossPos=dot(local,crossAxis);
                    highp float peak=.22+paneSeed*.38;
                    highp float pulse=exp(-pow((paneTime-peak)/max(.018,glintDuration*.35),2.0));
                    highp float eligible=step(.25,fract(paneSeed*17.37));
                    highp float width=max(.015,glintWidth*.30);
                    highp float sweep=-.9+paneTime*2.5+paneSeed*.3;
                    highp float line=exp(-pow((pos-sweep)/width,2.0));
                    highp float shoulder=exp(-pow((pos-sweep)/(width*3.5),2.0));
                    highp float spot=exp(-pow(crossPos/(width*3.0+.06),2.0))*line;
                    highp float highlight=pulse*eligible*(.20+.80*facing)*specular*material;
                    highp float band=exp(-pow((pos-.35-paneTime*.25)/.12,2.0));
                    lowp vec3 tint=mix(accent.rgb,vec3(1.0),0.65);
                    highp float reflectLight=(facing*.08+grazing*.30+band*(.08+.35*facing))*reflection*material;
                    highp float alpha=mix(1.0,glassOpacity+grazing*.15,material)*fade;
                    lowp vec3 colour=mix(image,through,material*.18)*(1.0-grazing*.20);
                    colour+=tint*reflectLight+tint*rim*glints*material*(.18+grazing*.55);
                    // Analytic glint mask: bright white core, small accent shoulder, per-pane timing.
                    lowp vec3 emission=vec3(1.0)*(line*.85+spot*1.5)*highlight+accent.rgb*shoulder*highlight*.40;
                    if(part>0.5){alpha=fade*material*.75*mix(1.0,smoothstep(0.0,.20,splitStage),secondaryPane);colour=mix(accent.rgb*.20,vec3(.6),facing*.35)+tint*glints*(.10+grazing*.35);emission*=.5;}
                    gl_FragColor=vec4(colour*alpha+emission*fade,alpha)*qt_Opacity;
                }"
            onStatusChanged:if(status===ShaderEffect.Error){console.warn('Batched Voronoi glass:',log);shards.failed();}
        }
    }

    Image {id:flareImage;source:"../assets/effects/optical-flare.png";visible:false;smooth:true;mipmap:true}
    Item {
        id:flares;objectName:"relayOpticalFlares";anchors.fill:parent;z:3
        visible:shards.geometryReady && amount>0 && flareCount>0 && shards.progress>0.001 && shards.progress<.999
        property real amount:(shards.options.fractureFlare===undefined ? 100:shards.options.fractureFlare)/100
        property int flareCount:Math.min(shards.cells.length,shards.options.fractureFlareCount===undefined ? 8:shards.options.fractureFlareCount)
        property real flareSpan:(shards.options.fractureFlareSpan===undefined ? 100:shards.options.fractureFlareSpan)/100
        property real haloRadius:shards.options.fractureFlareHalo===undefined ? 48:shards.options.fractureFlareHalo
        property real bloom:(shards.options.fractureFlareBloom===undefined ? 150:shards.options.fractureFlareBloom)/100
        function hash(x,y){var v=Math.sin(x*127.1+y*311.7+shards.randomSeed)*43758.5453;return v-Math.floor(v);}
        function pose(index,phase){
            var c=shards.cells[Math.min(shards.cells.length-1,Math.floor((index+.5)*shards.cells.length/Math.max(1,flareCount)))];
            if(!c)return {x:0,y:0,strength:0};
            var x=c.center.x,y=c.center.y,h=c.random;
            var rx=x-width*.5,ry=y-height*.5,dist=Math.sqrt(Math.pow(rx/(width*.5),2)+Math.pow(ry/(height*.5),2))/Math.SQRT2;
            var rank=Math.max(0,Math.min(1,dist+(h-.5)*(shards.options.fractureScatter||0)/100*.15));
            var t=Math.max(0,Math.min(1,(phase-rank*.55)/.45)),move=t*t;
            var spin=(shards.options.fractureSpin||0)*Math.PI/180;
            var ax=(hash(x+37,y+37)-.5)*2*spin*move,ay=(h-.5)*2*spin*move;
            var facing=Math.pow(Math.abs((-.4*Math.sin(ay)*Math.cos(ax)-.25*Math.sin(ax)+1.9*Math.cos(ay)*Math.cos(ax))/Math.sqrt(.16+.0625+3.61)),8);
            var duration=(shards.options.fractureGlintDuration===undefined ? 80:shards.options.fractureGlintDuration)/(Math.max(200,shards.options.fractureMs||1200)*.45);
            var pulse=Math.exp(-Math.pow((t-(.22+h*.38))/Math.max(.035,duration*.60),2));
            var end=Math.max(0,Math.min(1,(t-.75)/.25));end=end*end*(3-2*end);
            var travel=shards.options.fractureTravel||0,spread=(shards.options.fractureSeparation===undefined ? 45:shards.options.fractureSeparation)/100*.65;
            var length=Math.sqrt(rx*rx+ry*ry)||1;
            var px=rx+(rx/length+(hash(x+141,y+141)-.5)*spread)*travel*move*(.45+h*.55);
            var py=ry+(ry/length+(hash(x+212,y+212)-.5)*spread)*travel*move*(.45+h*.55);
            var depth=(dist<.45 ? .65+h*.35:(h-.5)*1.6)*travel*move;
            var camera=Math.max(width,height)*1.4,w=Math.max(camera*.15,camera-depth)/camera;
            return {x:px/w+width*.5,y:py/w+height*.5,strength:pulse*(.35+.65*facing)*(1-end),size:width*flareSpan*(.60+.65*(1-Math.min(1,dist)))*(.78+hash(x+411,y+411)*.44)};
        }
        // Bounded texture quads, with centre-weighted seeded sizes. One shared low-resolution halo.
        Item { id:flareLayer;anchors.fill:parent
        Repeater {
            id:flareSprites;objectName:"relayOpticalFlareRepeater"
            model:flares.visible ? flares.flareCount:0
            ShaderEffect {
                objectName:"relayOpticalFlareSprite"
                property var position:flares.pose(index,shards.progress)
                width:position.size||1;height:width/3;x:position.x-width*.5;y:position.y-height*.5
                visible:position.strength>.005 && x+width>0 && y+height>0 && x<shards.width && y<shards.height
                property variant source:flareImage
                property real strength:position.strength*flares.amount*3
                property color accent:shards.accent
                fragmentShader:"
                    uniform sampler2D source;
                    uniform highp float strength;
                    uniform lowp vec4 accent;
                    uniform lowp float qt_Opacity;
                    varying highp vec2 qt_TexCoord0;
                    void main(){lowp vec4 tex=texture2D(source,qt_TexCoord0);highp float core=pow(max(tex.r,max(tex.g,tex.b)),4.0);lowp vec3 tint=mix(accent.rgb,vec3(1.0),core);gl_FragColor=vec4(tex.rgb*tint*strength*qt_Opacity,0.0);}
                "
                onStatusChanged:if(status===ShaderEffect.Error)console.warn("Optical flare:",log)
            }
        }
        }
        ShaderEffectSource {id:flareLight;sourceItem:flareLayer;hideSource:false;live:flares.visible;visible:false;textureSize:Qt.size(Math.ceil(shards.width/4),Math.ceil(shards.height/4))}
        FastBlur {
            id:flareBlur;source:flareLight;visible:false;cached:false;transparentBorder:true
            width:shards.width/Math.max(1,flares.haloRadius/64);height:shards.height/Math.max(1,flares.haloRadius/64)
            radius:Math.min(64,flares.haloRadius)
        }
        ShaderEffectSource {id:flareHalo;sourceItem:flareBlur;hideSource:true;live:flares.visible;visible:false;textureSize:Qt.size(Math.ceil(shards.width/4),Math.ceil(shards.height/4))}
        ShaderEffect {
            objectName:"relayOpticalFlareBloom";anchors.fill:parent;visible:flares.haloRadius>0 && flares.bloom>0
            property variant source:flareHalo
            property real strength:flares.bloom*1.25
            property color accent:shards.accent
            fragmentShader:"\n varying highp vec2 qt_TexCoord0;\n uniform sampler2D source;\n uniform highp float strength;\n uniform lowp vec4 accent;\n uniform lowp float qt_Opacity;\n void main(){lowp vec4 c=texture2D(source,qt_TexCoord0);gl_FragColor=vec4(c.rgb*accent.rgb*strength*qt_Opacity,0.0);}\n"
            onStatusChanged:if(status===ShaderEffect.Error)console.warn("Optical flare bloom:",log)
        }
    }
}


