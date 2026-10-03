import QtQuick 2.3
import SortFilterProxyModel 0.2
import "components"
import "models"

FocusScope {
    id: root
    focus: true

    property int tabIndex: 1
    readonly property var tabNames: ["RECENT", "LIBRARY", "FAVORITES"]
    readonly property var sourceNames: ["ALL", "LOCAL", "STEAM"]
    property int sourceIndex: 0
    property int actionIndex: 0 // PLAY is the primary action
    onNavZoneChanged: if(navZone===3) { feedback("playFocus");playFocusFlash.restart(); }
    property int navZone: 2 // 2 rail, 3 actions; top navigation is shortcut-only
    property bool lastInputKeyboard: true
    readonly property bool keyboardHints: preferences.prompts === 1 || (preferences.prompts === 0 && lastInputKeyboard)
    readonly property string controllerStyle: preferences.prompts === 3 ? "playstation" : "xbox"
    property bool splashOpen: true
    property bool splashResolved: false
    function startStartupSplash() {
        splashStartupTimeout.stop();
        if(splashResolved || !splashOpen) return;
        splashResolved=true;
        if(!preferences.startupSplash) finishStartupSplash();
        else if(splashLoader.item) splashLoader.item.begin();
    }
    function finishStartupSplash() {
        splashResolved=true;splashStartupTimeout.stop();splashOpen=false;navZone=2;
        Qt.callLater(function(){gameRail.forceActiveFocus();});
    }
    Timer {id:splashStartupTimeout;interval:1200;onTriggered:root.startStartupSplash()}
    Loader {
        id:splashLoader;objectName:"relaySplashLoader";anchors.fill:parent;z:50000
        active:root.splashOpen;source:"components/StartupSplash.qml"
        onLoaded:{item.owner=root;item.forceActiveFocus();if(root.splashResolved) item.begin();}
        onStatusChanged:if(status===Loader.Error) root.finishStartupSplash()
    }
    Connections {target:splashLoader.item;ignoreUnknownSignals:true;onFinished:root.finishStartupSplash()}
    property bool settingsOpen: false
    property bool settingsLoaded: false
    property var menuPalette: menuStyle
    MenuPalette { id:menuStyle; accent:root.accent;highContrast:root.preferences.highContrast }
    property var preferences: defaultPreferences()
    readonly property var builtInAccents:["RELAY GREEN","CYAN","AMBER","WHITE","RED","CUSTOM"]
    function colourNames(items) { return builtInAccents.concat(items.filter(function(c){return builtInAccents.indexOf(c.name.toUpperCase())<0;}).map(function(c){return c.name;})); }
    readonly property var accentNames:colourNames(preferences.savedColours)
    function colourIndex(name,items) { for(var i=0;i<items.length;i++) if(items[i].name.toUpperCase()===name.toUpperCase()) return i;return -1; }
    function accentValue() {
        var name=accentNames[preferences.accent] || builtInAccents[0];
        var index=colourIndex(name,preferences.savedColours);
        if(preferences.accent===5) return Qt.rgba(preferences.red/255,preferences.green/255,preferences.blue/255,1);
        if(index>=0) {var c=preferences.savedColours[index];return Qt.rgba(c.red/255,c.green/255,c.blue/255,1);}
        return ["#8fcdaa","#86cdd3","#cbb382","#d2dbd7","#d46a70"][Math.min(4,preferences.accent)];
    }
    readonly property color accent:accentValue()
    readonly property real textScale: [1, 1.12, 1.25][preferences.textSize]
    readonly property real motionStrength: [0,1,1.35,1.7][preferences.animationLevel]
    readonly property var motionPreferences: {
        var p={};for(var k in preferences) p[k]=preferences[k];
        p.cardScale=100+(preferences.cardScale-100)*motionStrength;
        p.cardLift=0;p.cardTilt=preferences.cardTilt*motionStrength;
        p.parallaxDepth=preferences.parallaxDepth*motionStrength;
        if(preferences.reducedMotion) {
            p.animation=false;p.cardScale=100;p.cardTilt=0;p.parallaxDepth=0;p.motionMs=0;
            p.transitionMode=1;p.transitionMs=180;p.particleCount=0;p.typewriter=false;
        }
        if(preferences.reducedFlashes) {
            if(p.transitionMode===6 || p.transitionMode===7) p.transitionMode=1;
            p.fractureFlare=0;p.fractureSpecular=0;p.frostFlash=0;
            p.decodeGlow=0;p.decodeBloomIntensity=0;p.decodeAnimate=false;
            p.prismSplit=0;p.particleGlint=0;
        }
        return p;
    }
    FontLoader { id:jetFont; source:"assets/fonts/JetBrainsMono.ttf" }
    FontLoader { id:plexFont; source:"assets/fonts/IBMPlexMono.ttf" }
    FontLoader { id:spaceFont; source:"assets/fonts/Rajdhani.ttf" }
    FontLoader { id:inconsolataFont; source:"assets/fonts/Oxanium.ttf" }
    readonly property string monoFont: ["Consolas",jetFont.name || "monospace",plexFont.name || "monospace",spaceFont.name || "monospace",inconsolataFont.name || "monospace"][preferences.fontStyle]
    property string helperConnection: "Checking..."
    readonly property int backgroundTransitionDuration: hero.transitionDuration
    readonly property bool shaderSupported: hero.useShader
    property string configStatus: "Loading configuration..."
    property int preferenceRevision: 0
    property bool configWriting: false
    property bool configPending: false
    property int configAttempts: 0
    function defaultPreferences() { return {"helperAutoStart":false,"startupSplash":true,"splashWait":false,"reducedMotion":false,"reducedFlashes":false,"highContrast":false,"staticCursor":false,"trailerVolume":50,"fractureFlareSpan":100,"fractureFlareHalo":48,"fractureFlareBloom":150,"backgroundResolution":3,"schemaVersion":2,"accent":0,"red":143,"green":205,"blue":170,"prompts":0,"textSize":0,"brightness":100,"animation":true,"synopsis":true,"typewriter":true,"sounds":false,"transitionMode":4,"triangleSize":44,"transitionMs":650,"parallaxDepth":12,"prismStrength":25,"cardWidth":280,"cardScale":112,"cardTilt":8,"cardLift":0,"motionMs":480,"typewriterMs":38,"blinkMs":550,"trackOpacity":72,"iconTint":80,"soundVolume":24,"synopsisMs":8,"metadataMs":18,"captionMs":18,"cardAspect":230,"thumbnailFrames":{},"plexusEdges":35,"plexusFade":45,"plexusMotion":20,"prismSplit":0,"particleCount":24,"particleSize":2,"particleVariation":50,"particleSpeed":25,"particleOpacity":18,"animationLevel":1,"prismDistance":12,"prismAngle":0,"frostBlur":16,"frostRevealMs":900,"frostHoldMs":50,"frostSharpMs":800,"frostFlash":100,"particleWind":0,"particleGlint":0,"frostScatter":30,"frostGlintWidth":40,"frostGlintLength":14,"particlePlacement":0,"particleEdgeBias":50,"particleTop":100,"particleBottom":100,"particleLeft":100,"particleRight":100,"particleLifetime":45,"fontStyle":0,"overdrive":false,"savedColours":[],"particleCenterFade":0,"wipeMs":750,"wipeAngle":20,"wipeSoftness":0,"wipeReverse":false,"wipeFollow":true,"decodeMs":1150,"decodeCell":10,"decodeScatter":35,"decodeHold":45,"decodeGlow":60,"fractureMs":1200,"fractureSize":320,"fractureDepth":18,"fractureTilt":6,"fractureScatter":50,"fractureGlints":55,"weaveMs":1100,"weaveWidth":28,"weaveBend":12,"weaveAngle":0,"weaveStagger":40,"weaveGlow":45,"weaveContours":30,"glowRadius":32,"glowIntensity":100,"fractureSplit":20,"fractureChildren":4,"fractureSplitAt":38,"fractureSeparation":45,"fractureSpecular":100,"fractureGlintWidth":18,"fractureGlintDuration":80,"decodeHaloRadius":20,"decodeBloomIntensity":35,"weaveHaloRadius":40,"weaveBloomIntensity":150,"fractureLimit":128,"fractureImpactRadius":45,"fractureCoreSplit":40,"fractureFlare":100,"fractureFlareSize":280,"fractureFlareCount":8,"fractureRandomness":85,"fractureTravel":420,"fractureSpin":85,"fractureOpacity":45,"fractureReflection":85,"fractureThickness":8,"fractureBevel":3,"decodeAngle":0,"decodeSoftness":0,"decodeCharacterMs":100,"decodeReverse":false,"decodeFollow":true,"decodeAnimate":true,"transitionSound":1,"transitionVolume":25,"soundPack":0,"glintTint":85,"particleDensityBias":false,"frostGlintMs":80}; }
    function cleanPreferences(stored) {
        var clean=defaultPreferences(); var ranges={"trailerVolume":[0,100],"fractureFlareSpan":[20, 180],"fractureFlareHalo":[0, 128],"fractureFlareBloom":[0, 400],"backgroundResolution":[0, 4],"schemaVersion":[2,2],"accent":[0,37],"red":[0,255],"green":[0,255],"blue":[0,255],"prompts":[0,3],"textSize":[0,2],"brightness":[0,100],"transitionMode":[0,7],"triangleSize":[18,180],"transitionMs":[100,2000],"parallaxDepth":[0,50],"prismStrength":[0,100],"cardWidth":[220,640],"cardScale":[100,118],"cardTilt":[0,18],"cardLift":[0,0],"motionMs":[80,700],"typewriterMs":[10,120],"blinkMs":[200,1400],"trackOpacity":[20,95],"iconTint":[0,100],"soundVolume":[0,100],"synopsisMs":[1,80],"metadataMs":[5,100],"captionMs":[5,100],"cardAspect":[160,320],"plexusEdges":[0,100],"plexusFade":[15,70],"plexusMotion":[0,100],"prismSplit":[0,100],"particleCount":[0,180],"particleSize":[1,8],"particleVariation":[0,100],"particleSpeed":[0,100],"particleOpacity":[0,100],"animationLevel":[0,3],"prismDistance":[0,48],"prismAngle":[0,360],"frostBlur":[0,30],"frostRevealMs":[200,4000],"frostHoldMs":[0,1500],"frostSharpMs":[200,4000],"frostFlash":[0,100],"particleWind":[0,100],"particleGlint":[0,100],"frostScatter":[0,100],"frostGlintWidth":[5,100],"frostGlintLength":[5,35],"particlePlacement":[0,2],"particleEdgeBias":[0,100],"particleTop":[0,200],"particleBottom":[0,200],"particleLeft":[0,200],"particleRight":[0,200],"particleLifetime":[5,180],"fontStyle":[0,4],"particleCenterFade":[0,100],"wipeMs":[100,4000],"wipeAngle":[0,360],"wipeSoftness":[0,80],"decodeMs":[200, 4000],"decodeCell":[6, 12],"decodeScatter":[0, 100],"decodeHold":[20, 80],"decodeGlow":[0, 100],"fractureMs":[200, 4000],"fractureSize":[70, 400],"fractureDepth":[0, 60],"fractureTilt":[0, 18],"fractureScatter":[0, 100],"fractureGlints":[0, 100],"weaveMs":[200, 4000],"weaveWidth":[8, 640],"weaveBend":[0, 200],"weaveAngle":[0, 180],"weaveStagger":[0, 200],"weaveGlow":[0, 200],"weaveContours":[0, 200],"glowRadius":[0,64],"glowIntensity":[0,200],"fractureSplit":[0, 100],"fractureChildren":[2, 5],"fractureSplitAt":[15, 75],"fractureSeparation":[0, 100],"fractureSpecular":[0, 200],"fractureGlintWidth":[5, 60],"fractureGlintDuration":[16,300],"decodeHaloRadius":[0, 64],"decodeBloomIntensity":[0, 200],"weaveHaloRadius":[0, 128],"weaveBloomIntensity":[0, 400],"fractureLimit":[32, 128],"fractureImpactRadius":[15, 80],"fractureCoreSplit":[0, 100],"fractureFlare":[0, 300],"fractureFlareSize":[60, 800],"fractureFlareCount":[0, 16],"fractureRandomness":[0,100],"fractureTravel":[0,1200],"fractureSpin":[0,180],"fractureOpacity":[10,100],"fractureReflection":[0,150],"fractureThickness":[0,32],"fractureBevel":[0,12],"decodeAngle":[0,360],"decodeSoftness":[0,40],"decodeCharacterMs":[30,500],"transitionSound":[0, 3],"transitionVolume":[0, 100],"soundPack":[0,3],"glintTint":[0,100],"frostGlintMs":[20,700]};
        if (!stored || typeof stored!=="object") return clean;
        for(var k in clean) {
            if(typeof clean[k]==="boolean") { if(typeof stored[k]==="boolean") clean[k]=stored[k]; }
            else if(ranges[k] && typeof stored[k]==="number" && isFinite(stored[k])) clean[k]=Math.max(ranges[k][0],Math.min(ranges[k][1],Math.round(stored[k])));
        }
        // Copy legacy shared glow to both modes once; subsequent changes stay independent.
        for(var modeIndex=0;modeIndex<2;modeIndex++) {
            var modeName=modeIndex===0 ? "decode":"weave";
            if(stored[modeName+"HaloRadius"]===undefined && typeof stored.glowRadius==="number") clean[modeName+"HaloRadius"]=clean.glowRadius;
            if(stored[modeName+"BloomIntensity"]===undefined && typeof stored.glowIntensity==="number") clean[modeName+"BloomIntensity"]=clean.glowIntensity;
        }
        if(!stored.schemaVersion && stored.accent===4) clean.accent=5;
        clean.thumbnailFrames=cleanFrames(stored.thumbnailFrames);
        clean.savedColours=cleanColours(stored.savedColours);
        clean.accent=Math.min(clean.accent,colourNames(clean.savedColours).length-1);
        clean.cardLift=0;
        if(!clean.overdrive) clean.cardWidth=Math.min(360,clean.cardWidth);
        if(typeof stored.animationLevel!=="number") clean.animationLevel=stored.animation===false ? 0:1;
        clean.animation=clean.animationLevel>0;
        if(typeof stored.frostGlintMs!=="number" && typeof stored.frostGlintLength==="number") clean.frostGlintMs=Math.round(clean.frostSharpMs*stored.frostGlintLength/100);
        clean.frostGlintMs=Math.max(20,Math.min(700,Math.round(clean.frostSharpMs*.4),clean.frostGlintMs));
        clean.schemaVersion=2; return clean;
    }
    function cleanColours(items) {
        if(!Array.isArray(items)) return [];
        var result=[],names={};
        for(var i=0;i<Math.min(32,items.length);i++) {
            var c=items[i]; if(!c || typeof c.name!=="string" || !c.name.trim()) continue;
            var name=c.name.trim().slice(0,32);if(name.toUpperCase()==="CUSTOM" || names[name.toUpperCase()]) continue;
            if([c.red,c.green,c.blue].some(function(x){return typeof x!=="number" || !isFinite(x);})) continue;
            names[name.toUpperCase()]=true;result.push({name:name,red:Math.max(0,Math.min(255,Math.round(c.red))),green:Math.max(0,Math.min(255,Math.round(c.green))),blue:Math.max(0,Math.min(255,Math.round(c.blue)))});
        } return result;
    }
    property bool colourEditorOpen:false
    property string colourMessage:""
    property string colourConfirmation:""
    property var pendingColour:null
    readonly property string colourConfirmationText:colourConfirmation==="delete" ? "Remove saved colour "+(pendingColour ? pendingColour.name:"")+"? Built-in presets revert to their original colour." : "A colour named "+(pendingColour ? pendingColour.name:"")+" already exists. Overwrite it, or cancel and choose another name."
    function saveNamedColour(name) {
        name=name.trim().slice(0,32);colourMessage="";
        if(!name) {colourMessage="Enter a colour name.";return;}
        if(name.toUpperCase()==="CUSTOM") {colourMessage="CUSTOM is reserved. Please choose another name.";return;}
        var c={name:name,red:Math.round(accent.r*255),green:Math.round(accent.g*255),blue:Math.round(accent.b*255)};
        var builtin=builtInAccents.indexOf(name.toUpperCase());if(builtin>=0) c.name=builtInAccents[builtin];
        if(colourIndex(name,preferences.savedColours)>=0 || builtin>=0) {pendingColour=c;colourConfirmation="overwrite";return;}
        storeColour(c);
    }
    function storeColour(c) {
        var items=preferences.savedColours.slice(0),index=colourIndex(c.name,items);
        if(index>=0) items[index]=c;else if(items.length<32) items.push(c);else {colourMessage="32 colours saved. Remove one or reuse a name.";return;}
        var next={};for(var k in preferences) next[k]=preferences[k];next.savedColours=items;
        next.accent=colourNames(items).map(function(n){return n.toUpperCase();}).indexOf(c.name.toUpperCase());
        preferences=next;setPreference("accent",next.accent);colourEditorOpen=false;settingsPanel.forceActiveFocus();
    }
    function requestRemoveColour() {
        var name=accentNames[preferences.accent],index=colourIndex(name,preferences.savedColours);
        if(index<0) return;pendingColour={name:name};colourConfirmation="delete";
    }
    function finishColourConfirmation(confirm) {
        var action=colourConfirmation,c=pendingColour;colourConfirmation="";pendingColour=null;
        if(confirm && action==="overwrite") storeColour(c);
        else if(confirm && action==="delete") {
            var items=preferences.savedColours.filter(function(item){return item.name.toUpperCase()!==c.name.toUpperCase();});
            var next={};for(var k in preferences) next[k]=preferences[k];next.savedColours=items;
            var builtin=builtInAccents.indexOf(c.name.toUpperCase());next.accent=builtin>=0 ? builtin:0;
            preferences=next;setPreference("accent",next.accent);settingsPanel.forceActiveFocus();
        } else if(colourEditorOpen) colourNameEditor.restoreFocus();else settingsPanel.forceActiveFocus();
    }
    function loadNamedColour(index) {
        var c=preferences.savedColours[index];if(!c) return;
        setPreference("accent",accentNames.map(function(n){return n.toUpperCase();}).indexOf(c.name.toUpperCase()));
    }
    function cleanFrames(frames) {
        var clean={}; if(!frames || typeof frames!=="object" || Array.isArray(frames)) return clean;
        for(var key in frames) {
            var f=frames[key];if(!f || typeof f!=="object" || key.length>4096) continue;
            var copy={x:50,y:50,zoom:100};
            for(var k in copy) if(typeof f[k]==="number" && isFinite(f[k])) copy[k]=Math.max(k==="zoom" ? 100:0,Math.min(k==="zoom" ? 200:100,Math.round(f[k])));
            clean[key]=copy;
        } return clean;
    }
    property bool metadataEditorOpen:false
    property int metadataField:0
    property var metadataDraft: ({title:"",developer:"",publisher:"",genres:"",year:"",summary:""})
    property string metadataQueryBackup:""
    readonly property var metadataFields:["title","developer","publisher","genres","year","summary"]
    function setMetadataDraft(key,value) { var next={};for(var k in metadataDraft) next[k]=metadataDraft[k];next[key]=value;
metadataDraft=next; }
    function openMetadataEditor() {
        if(!selectedMatch || applyBusy) return;
        var m=selectedMatch;metadataDraft={title:m.title||"",developer:m.developer||"",publisher:m.publisher||"",genres:(m.genres||[]).join(", "),year:String(m.year||""),summary:m.summary||""};
        metadataQueryBackup=dataQuery;metadataField=0;metadataEditorOpen=true;
        Qt.callLater(function(){metadataEditor.focusRow();});
    }
    function saveMetadataDraft() {
        if(!metadataDraft.title.trim()) return;
        var next={};for(var k in selectedMatch) next[k]=selectedMatch[k];
        next.title=metadataDraft.title.trim();next.developer=metadataDraft.developer.trim();next.publisher=metadataDraft.publisher.trim();next.summary=metadataDraft.summary;
        next.genres=metadataDraft.genres.split(",").map(function(x){return x.trim();}).filter(function(x){return x.length>0;});
        var year=parseInt(metadataDraft.year,10);
        if(metadataDraft.year.trim() && (!isFinite(year) || year<1900 || year>2200)) return;
        if(year!==selectedMatch.year) next.release_timestamp=isFinite(year) ? Date.UTC(year,0,1)/1000 : 0;
        next.year=isFinite(year) ? year:0;selectedMatch=next;metadataEditorOpen=false;dataQuery=metadataQueryBackup;dataOverlay.forceActiveFocus();
    }
    function cancelMetadataDraft() { metadataEditorOpen=false;searchKeyboardOpen=false;dataQuery=metadataQueryBackup;dataOverlay.forceActiveFocus(); }
    function editMetadataFieldOnPad() { dataQuery=metadataDraft[metadataFields[metadataField]] || "";searchKeyboardIndex=0;searchKeyboardOpen=true;dataOverlay.forceActiveFocus(); }
    function handleMetadataKey(event) {
        observeInput(event);event.accepted=true;
        if(event.key===Qt.Key_Escape || api.keys.isCancel(event)) { if(!event.isAutoRepeat) cancelMetadataDraft(); }
        else if(event.key===Qt.Key_Up || event.key===Qt.Key_Backtab || (event.key===Qt.Key_Tab && (event.modifiers & Qt.ShiftModifier))) { metadataField=(metadataField+6)%7;metadataEditor.focusRow(); }
        else if(event.key===Qt.Key_Down || event.key===Qt.Key_Tab) { metadataField=(metadataField+1)%7;metadataEditor.focusRow(); }
        else if(event.key===Qt.Key_Return || event.key===Qt.Key_Enter || api.keys.isAccept(event)) { if(!event.isAutoRepeat) { if(metadataField===6) saveMetadataDraft();else if(!keyboardHints) editMetadataFieldOnPad(); } }
        else event.accepted=false;
    }
    property bool cropEditorOpen:false
    property int cropField:0
    property var cropDraft: ({x:50,y:50,zoom:100})
    property url cropSource
    function frameKey(game) { return normalizedPath(gamePath(game)) || (game ? gameTitleText(game):""); }
    function frameForGame(game) { return preferences.thumbnailFrames[frameKey(game)] || {x:50,y:50,zoom:100}; }
    property var pendingCrop: ({x:50,y:50,zoom:100})
    property string pendingCover:""
    readonly property string activeCover: artworkData.cover && artworkData.cover.length && coverIndex<artworkData.cover.length ? String(artworkData.cover[coverIndex].url) : ""
    onActiveCoverChanged: if(dataOpen && activeCover!==pendingCover) { pendingCover=activeCover;pendingCrop={x:50,y:50,zoom:100}; }
    function openCropEditor() {
        if(applyBusy || artworkLoading) return;
        if(artworkEditMode) confirmArtworkEdit();
        curationIndex=1;cropDraft={x:pendingCrop.x,y:pendingCrop.y,zoom:pendingCrop.zoom};
        cropSource=activeCover || gameAsset(currentGame,"boxFront");cropEditorOpen=true;dataOverlay.forceActiveFocus();
    }
    function panCrop(dx,dy) {
        cropDraft={x:Math.max(0,Math.min(100,cropDraft.x-dx*2)),y:Math.max(0,Math.min(100,cropDraft.y-dy*2)),zoom:cropDraft.zoom};
    }
    function zoomCrop(delta) { cropDraft={x:cropDraft.x,y:cropDraft.y,zoom:Math.max(100,Math.min(200,cropDraft.zoom+delta*2))}; }
    function finishCrop() { pendingCrop={x:cropDraft.x,y:cropDraft.y,zoom:cropDraft.zoom};cropEditorOpen=false;dataOverlay.forceActiveFocus(); }
    function commitCrop(frame) {
        var frames={};for(var k in preferences.thumbnailFrames) frames[k]=preferences.thumbnailFrames[k];
        frames[frameKey(currentGame)]={x:frame.x,y:frame.y,zoom:frame.zoom};setPreference("thumbnailFrames",frames);
    }
    function setPreference(key,value) {
        var next={}; for(var k in preferences) next[k]=preferences[k];
        next[key]=value;
        if(key==="red" || key==="green" || key==="blue") next.accent=5;
        if(key==="accent" && value!==5) {
            var name=colourNames(next.savedColours)[value],index=colourIndex(name || "",next.savedColours);
            var c=index>=0 ? next.savedColours[index]:null;
            var colour=c ? Qt.rgba(c.red/255,c.green/255,c.blue/255,1):["#8fcdaa","#86cdd3","#cbb382","#d2dbd7","#d46a70"][value];
            if(colour) {var rgb=Qt.darker(colour,1);next.red=Math.round(rgb.r*255);next.green=Math.round(rgb.g*255);next.blue=Math.round(rgb.b*255);}
        }
        if(key==="animation") next.animationLevel=value ? Math.max(1,next.animationLevel):0;
        if(key==="animationLevel") next.animation=value>0;
        preferences=cleanPreferences(next); preferenceRevision++;
        if(settingsLoaded) { api.memory.set("relay.appearance",preferences); configPending=true; configAttempts=0; configSaveTimer.restart(); }
    }
    function saveConfiguration() {
        if(configWriting) { configPending=true; return; }
        configWriting=true; configPending=false; var revision=preferenceRevision;
        var request=new XMLHttpRequest();
        configStatus="Saving...";
        request.onreadystatechange=function() {
            if(request.readyState!==XMLHttpRequest.DONE) return;
            configWriting=false;
            if(request.status===200) { configStatus="Saved to relay-settings.json"; configAttempts=0; if(preferenceRevision!==revision || configPending) configSaveTimer.restart(); }
            else { configStatus="Saved in Pegasus; config file pending helper connection"; configPending=true; if(configAttempts++<3) { ensureHelper(); configSaveTimer.interval=1500; configSaveTimer.restart(); } }
        };
        request.open("POST","http://127.0.0.1:47831/theme-settings"); request.setRequestHeader("Content-Type","application/json"); request.send(JSON.stringify(preferences));
    }
    function loadConfiguration() {
        var revision=preferenceRevision; var request=new XMLHttpRequest();
        request.onreadystatechange=function() {
            if(request.readyState!==XMLHttpRequest.DONE) return;
            if(revision!==preferenceRevision) {root.startStartupSplash();return;}
            try {
                if(!request.responseText) throw new Error("No configuration yet");
                preferences=cleanPreferences(JSON.parse(request.responseText)); api.memory.set("relay.appearance",preferences); configStatus="Loaded relay-settings.json";
            } catch(e) { configStatus="Using saved Pegasus preferences"; configPending=true; configSaveTimer.restart(); }
            root.startStartupSplash();
        };
        request.open("GET",Qt.resolvedUrl("relay-settings.json")); request.send();
    }
    function replayTransition() {
        var other=currentGame ? gameAsset(currentGame,"background") : "";
        if(activeProvider.games.count>1) other=gameAsset(activeProvider.gameAt((gameRail.currentIndex+1)%activeProvider.games.count),"background") || other;
        hero.replay(other);
    }
    function feedback(kind) { uiSounds.play(kind); }
    function resetAppearance() {
        var previous=preferences,next=defaultPreferences();
        next.savedColours=previous.savedColours;next.thumbnailFrames=previous.thumbnailFrames;
        var keep=["startupSplash","splashWait","prompts","textSize","fontStyle","reducedMotion","reducedFlashes","highContrast","staticCursor"];
        for(var i=0;i<keep.length;i++) next[keep[i]]=previous[keep[i]];
        preferences=next;setPreference("prompts",previous.prompts);
    }
    function observeInput(event) {
        // Pegasus exposes controller buttons as 0x100000..0x10000c.
        // D-pad and keyboard arrows share Qt keys, so retain the last known device for arrows.
        if (event.key >= 1048576 && event.key <= 1048588) lastInputKeyboard = false;
        else if ((event.key >= Qt.Key_Space && event.key <= Qt.Key_AsciiTilde) || event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Escape || event.key === Qt.Key_Tab || event.key === Qt.Key_Backspace || event.key === Qt.Key_F1) lastInputKeyboard = true;
    }
    function observePointer() { lastInputKeyboard=true; }
    function openSettings() { if (splashOpen || dataOpen || rebuildPromptOpen) return; settingsOpen = true; settingsPanel.developer = false; settingsPanel.selected = 0; settingsPanel.forceActiveFocus(); ensureHelper(); }
    function closeSettings() { feedback("back"); settingsOpen = false; if (navZone === 2) gameRail.forceActiveFocus(); else root.forceActiveFocus(); }
    function promptButtons(action) {
        if (action === "category") return ["lb", "rb"];
        if (action === "source") return ["lt", "rt"];
        if (action === "settings") return ["ls"];
        if (action === "navigate") return ["dpad"];
        var defaults = {accept:"a", cancel:"b", details:"x", filters:"y"};
        var ids = ["a","b","x","y","lb","lt","ls","rb","rt","rs","view","menu","guide"];
        var keys = api.keys[action];
        if (keys) for (var i=0; i<keys.length; i++) { var id=keys[i].key-1048576; if (id >= 0 && id < ids.length) return [ids[id]]; }
        return [defaults[action] || "a"];
    }
    property string dataConfirmation:""
    property string dataBaseline:""
    function dataDraftSnapshot() {
        function art(kind,index) {var list=artworkData[kind] || [];return list.length && index<list.length ? String(list[index].url):"";}
        var m=selectedMatch || {};
        return JSON.stringify({id:m.id||0,title:m.title||"",developer:m.developer||"",publisher:m.publisher||"",year:m.year||0,genres:m.genres||[],summary:m.summary||"",hero:art("hero",heroIndex),cover:art("cover",coverIndex),logo:art("logo",logoIndex),crop:pendingCrop});
    }
    function hasDataChanges() {return dataOpen && dataBaseline.length>0 && dataBaseline!==dataDraftSnapshot();}
    function finishDataConfirmation(confirmed) {
        var action=dataConfirmation;dataConfirmation="";
        if(!confirmed) {dataOverlay.forceActiveFocus();return;}
        if(action==="clear") performClearMetadata();
        else if(action==="back") {backFromMatchNow();dataBaseline=dataDraftSnapshot();}
        else closeDataNow();
    }
    DataConfirmation {anchors.fill:parent;z:23000;owner:root;visible:root.dataConfirmation.length>0}
    property bool dataOpen: false
    property bool dataLoading: false
    property string dataQuery: currentGame ? currentGame.title : ""
    property var dataResults: []
    property int dataResultIndex: 0
    property string dataError: ""
    property var selectedMatch: null
    property bool matchLoading: false
    property bool artworkOpen: false
    property bool artworkLoading: false
    property var artworkData: ({ "hero": [], "logo": [], "cover": [] })
    property int heroIndex: 0
    property int logoIndex: 0
    property int coverIndex: 0
    property var sessionMetadataStatus: ({})
    property var persistentMetadataStatus: ({})
    property var liveGameData: ({})
    property int searchRequestId: 0
    property int matchRequestId: 0
    property int artworkRequestId: 0
    property bool searchCompleted: false
    property int dataFocus: 0 // search field, search button, results, clear, close
    property bool searchKeyboardOpen: false
    property int searchKeyboardIndex: 0
    readonly property var searchKeyboardKeys: ["A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z","0","1","2","3","4","5","6","7","8","9","SPACE","DELETE","CLEAR","DONE"]
    property bool helperStarting: false
    property int helperStartupAttempts: 0
    property string helperMessage: ""
    property string applyMessage: ""
    property bool applyBusy: false
    property int curationIndex: 0 // 0 hero, 1 cover, 2 logo, 3 apply, 4 clear
    property bool artworkEditMode: false
    property int artworkEditOriginalIndex: 0
    property string selectedGamePath: ""
    property bool libraryDirty: false
    property bool rebuildPromptOpen: false
    property int rebuildChoice: 0 // 0 rebuild, 1 later
    property var activeProvider: tabIndex === 0 ? recentModel : (tabIndex === 1 ? libraryModel : favoritesModel)
    property var currentGame: activeProvider && activeProvider.games.count > 0 ? activeProvider.gameAt(Math.min(gameRail.currentIndex, activeProvider.games.count - 1)) : null

    function changeTab(delta) {
        feedback("category");
        tabIndex = (tabIndex + delta + tabNames.length) % tabNames.length;
        navZone = 2;
        gameRail.resetSelection();
    }
    function changeSource(delta) {
        feedback("source");
        sourceIndex = (sourceIndex + delta + sourceNames.length) % sourceNames.length;
        navZone = 2;
        gameRail.resetSelection();
    }
    function focusZone(zone) {
        navZone = zone;

        root.forceActiveFocus();
    }
    function moveTab(delta) { changeTab(delta); gameRail.forceActiveFocus(); }
    function moveSource(delta) { changeSource(delta); gameRail.forceActiveFocus(); }
    function activateZone() {
        if(navZone!==2 && (navZone!==3 || actionIndex!==0)) feedback("confirm");
        if (navZone === 0 || navZone === 1) { navDown(); return; }
        if (navZone === 2) { navZone = 3; actionIndex = 0; return; }
        if (navZone === 3) {
            if (actionIndex === 0) launchCurrent();
            else if(actionIndex===1 && trailerAvailable) openTrailer();
            else openData();
        }
    }
    function navUp() { if(navZone!==2) feedback("move"); navZone = navZone === 2 ? 3 : 2; if (navZone === 2) gameRail.forceActiveFocus(); else root.forceActiveFocus(); }
    function navDown() { navUp(); }
    function normalizedPath(path) { return String(path || "").replace(/\\/g, "/").toLowerCase(); }
    function gameData(game) { return liveGameData[normalizedPath(gamePath(game))] || null; }
    function gameAsset(game, kind) {
        if (!game) return "";
        var data = gameData(game);
        if (data && data.assets && data.assets[kind] !== undefined) return data.assets[kind];
        return game.assets[kind] || "";
    }
    function gameTitleText(game) {
        var data = gameData(game);
        return data && data.metadata && data.metadata.title ? data.metadata.title : (game ? game.title : "");
    }
    function gameDeveloper(game) {
        var data = gameData(game);
        return data && data.metadata ? (data.metadata.developer || "PC GAME") : (game ? game.developer || "PC GAME" : "");
    }
    function gameSynopsis(game) {
        if (!game) return "";
        var data = gameData(game);
        if (data && data.metadata && data.metadata.summary !== undefined) return data.metadata.summary;
        return game.summary || game.description || "";
    }
    function focusData(control) {
        dataFocus = control === 2 && !dataResults.length ? 0 : control;
        if (dataFocus === 0 && !selectedMatch && !searchKeyboardOpen) searchInput.forceActiveFocus();
        else dataOverlay.forceActiveFocus();
    }
    function cycleDataFocus(delta) {
        if (selectedMatch) { curationIndex = (curationIndex + delta + 7) % 7; dataOverlay.forceActiveFocus(); return; }
        var next = (dataFocus + delta + 5) % 5;
        if (next === 2 && !dataResults.length) next = (next + delta + 5) % 5;
        focusData(next);
    }
    function moveDataFocus(dx, dy) {
        if (dataFocus === 2) {
            if (dy < 0 && dataResultIndex === 0) focusData(0);
            else if (dy !== 0) {
                dataResultIndex = Math.max(0, Math.min(dataResults.length - 1, dataResultIndex + dy));
                resultList.positionViewAtIndex(dataResultIndex, ListView.Contain);
            } else if (dx !== 0) focusData(dx > 0 ? 4 : 3);
        } else if (dataFocus === 3 || dataFocus === 4) {
            if (dx !== 0) focusData(dataFocus === 3 ? 4 : 3);
            else if (dy > 0) focusData(dataFocus === 3 ? 0 : 1);
        } else {
            if (dx !== 0) focusData(dataFocus === 0 ? 1 : 0);
            else if (dy < 0) focusData(dataFocus === 0 ? 3 : 4);
            else if (dy > 0 && dataResults.length) focusData(2);
        }
    }
    function activateDataFocus(keyboard) {
        if (dataFocus === 4) closeData();
        else if (dataFocus === 3) clearMetadata();
        else if (dataFocus === 2) { if (!matchLoading) selectDataMatch(); }
        else if (dataFocus === 0 && !keyboard) {
            searchKeyboardOpen = true; searchKeyboardIndex = 0; dataOverlay.forceActiveFocus();
        } else if (!dataLoading) searchMetadata();
    }
    function useSearchKeyboardKey() {
        var key = searchKeyboardKeys[searchKeyboardIndex];
        if (key === "DONE") {
            searchKeyboardOpen = false;
            if(metadataEditorOpen) { setMetadataDraft(metadataFields[metadataField],dataQuery);dataQuery=metadataQueryBackup;metadataEditor.focusRow(); }
            else focusData(1);
        }
        else if (key === "DELETE") dataQuery = dataQuery.slice(0, -1);
        else if (key === "CLEAR") dataQuery = "";
        else dataQuery += key === "SPACE" ? " " : key;
    }
    function handleDataKey(event) {
        observeInput(event);
        var accept = event.key === Qt.Key_Return || event.key === Qt.Key_Enter || api.keys.isAccept(event);
        var cancel = event.key === Qt.Key_Escape || api.keys.isCancel(event);
        var keyboard = event.key === Qt.Key_Return || event.key === Qt.Key_Enter;
        if(cropEditorOpen) {
            if((cancel || accept) && !event.isAutoRepeat) finishCrop();
            else if(event.key===Qt.Key_Left) panCrop(-1,0);
            else if(event.key===Qt.Key_Right) panCrop(1,0);
            else if(event.key===Qt.Key_Up) panCrop(0,-1);
            else if(event.key===Qt.Key_Down) panCrop(0,1);
            else if(event.key===Qt.Key_Minus || event.key===1048581) zoomCrop(-1);
            else if(event.key===Qt.Key_Plus || event.key===Qt.Key_Equal || event.key===1048584) zoomCrop(1);
            else if(event.key===Qt.Key_R || event.key===1048579) cropDraft={x:50,y:50,zoom:100};
            event.accepted=true;return;
        }
        if(metadataEditorOpen && !searchKeyboardOpen) { handleMetadataKey(event);return; }
        if(!searchKeyboardOpen && selectedMatch && !applyBusy && (event.key===Qt.Key_F2 || (event.key>=1048576 && event.key<=1048588 && api.keys.isDetails(event)))) { event.accepted=true;if(!event.isAutoRepeat) openMetadataEditor();return; }
        if(!searchKeyboardOpen && selectedMatch && !applyBusy && (event.key===Qt.Key_F3 || event.key===1048583)) { event.accepted=true;if(!event.isAutoRepeat) openArtwork(true);return; }
        if(!searchKeyboardOpen && selectedMatch && curationIndex===1 && (event.key===Qt.Key_Backspace || (event.key>=1048576 && event.key<=1048588 && api.keys.isFilters(event)))) { event.accepted=true;if(!event.isAutoRepeat) openCropEditor();return; }
        if (searchKeyboardOpen) {
            if (cancel && !event.isAutoRepeat) { searchKeyboardOpen = false;if(metadataEditorOpen) { dataQuery=metadataQueryBackup;metadataEditor.focusRow(); } else focusData(0); }
            else if (accept && !event.isAutoRepeat) useSearchKeyboardKey();
            else if (event.key === Qt.Key_Left) searchKeyboardIndex = (searchKeyboardIndex + 39) % 40;
            else if (event.key === Qt.Key_Right) searchKeyboardIndex = (searchKeyboardIndex + 1) % 40;
            else if (event.key === Qt.Key_Up) searchKeyboardIndex = (searchKeyboardIndex + 32) % 40;
            else if (event.key === Qt.Key_Down) searchKeyboardIndex = (searchKeyboardIndex + 8) % 40;
            event.accepted = true; return;
        }
        if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
            if (artworkEditMode) { event.accepted = true; return; }
            cycleDataFocus(event.key === Qt.Key_Backtab || (event.modifiers & Qt.ShiftModifier) ? -1 : 1);
            event.accepted = true; return;
        }
        if (selectedMatch) {
            if (artworkEditMode) {
                if (cancel && !event.isAutoRepeat) cancelArtworkEdit();
                else if (accept && !event.isAutoRepeat) confirmArtworkEdit();
                else if (event.key === Qt.Key_Left || event.key === Qt.Key_Right)
                    cycleArtwork(curationIndex === 0 ? "hero" : (curationIndex === 1 ? "cover" : "logo"), event.key === Qt.Key_Left ? -1 : 1);
            } else if (cancel && !event.isAutoRepeat) backFromMatch();
            else if (event.key === Qt.Key_Up) {
                if (curationIndex === 0) curationIndex = 6;
                else if (curationIndex === 6) curationIndex = 5;
                else if (curationIndex === 1 || curationIndex === 2) curationIndex = 0;
                else if (curationIndex === 3 || curationIndex === 4) curationIndex = 1;
            } else if (event.key === Qt.Key_Down) {
                if (curationIndex === 5) curationIndex = 6;
                else if (curationIndex === 6) curationIndex = 0;
                else if (curationIndex === 0) curationIndex = 1;
                else if (curationIndex === 1 || curationIndex === 2) curationIndex = 3;
                else curationIndex = 5;
            } else if (event.key === Qt.Key_Left || event.key === Qt.Key_Right) {
                if (curationIndex === 6) changeBackgroundResolution(event.key === Qt.Key_Left ? -1 : 1);
                else if (curationIndex === 1 || curationIndex === 2) curationIndex = curationIndex === 1 ? 2 : 1;
                else if (curationIndex === 3 || curationIndex === 4) curationIndex = curationIndex === 3 ? 4 : 3;
            } else if (accept && !event.isAutoRepeat) {
                if (curationIndex === 6) changeBackgroundResolution(1);
                else if (curationIndex === 5) backFromMatch();
                else if (!applyBusy && curationIndex <= 2) beginArtworkEdit();
                else if (!applyBusy && curationIndex === 3) applyMetadata();
                else if (!applyBusy) clearMetadata();
            }
            event.accepted = true; return;
        }
        if (cancel && !event.isAutoRepeat) { closeData(); event.accepted = true; }
        else if (accept && !event.isAutoRepeat) { activateDataFocus(keyboard); event.accepted = true; }
        else if (event.key === Qt.Key_Up || event.key === Qt.Key_Down || event.key === Qt.Key_Left || event.key === Qt.Key_Right) {
            moveDataFocus(event.key === Qt.Key_Left ? -1 : (event.key === Qt.Key_Right ? 1 : 0), event.key === Qt.Key_Up ? -1 : (event.key === Qt.Key_Down ? 1 : 0));
            event.accepted = true;
        }
    }
    function ensureHelper() {
        if (helperStarting) return;
        helperStarting = true; helperConnection = "Starting..."; helperStartupAttempts = 0;
        var request = new XMLHttpRequest();
        request.onreadystatechange = function() {
            if (request.readyState !== XMLHttpRequest.DONE) return;
            if (request.status === 200) { helperStarting = false; checkHelper(); refreshMetadataStatus(); }
            else {
                if(!preferences.helperAutoStart) {helperStarting=false;helperConnection="Offline";helperMessage="Optional helper is offline. Start it to find or edit artwork.";return;}
                helperMessage = "Starting metadata helper...";
                if (!Qt.openUrlExternally(Qt.resolvedUrl("relay-metadata/AUTO_START_HELPER.vbs"))) {
                    helperStarting = false; helperConnection = "Offline"; helperMessage = "Could not start metadata helper. Run START_HELPER.bat.";
                } else helperStartupTimer.start();
            }
        };
        request.open("GET", "http://127.0.0.1:47831/health"); request.send();
    }
    function updateGameData(path, data) {
        var next = {};
        for (var key in liveGameData) next[key] = liveGameData[key];
        next[normalizedPath(path)] = data;
        liveGameData = next;
        api.memory.set("relay.liveGameData", next);
    }
    function checkHelper() {
        helperMessage = "";
        var request = new XMLHttpRequest();
        request.onreadystatechange = function() {
            if (request.readyState !== XMLHttpRequest.DONE) return;
            if (request.status !== 200) { helperConnection = "Offline"; helperMessage = "Metadata helper is offline. Start START_HELPER.bat, then search again."; }
            else {
                try { var reply = JSON.parse(request.responseText); helperConnection = reply.ok ? "Connected" : "Configuration needed"; if (!reply.ok) helperMessage = reply.error || "Check the helper configuration."; }
                catch (e) { helperConnection = "Invalid response"; helperMessage = "Could not read helper status."; }
            }
        };
        request.open("GET", "http://127.0.0.1:47831/health"); request.send();
    }
    property bool trailerOpen:false
    property url trailerUrl
    property string trailerTitle:""
    // No local-file or browser fallback. Enable only after native streaming is verified.
    readonly property bool trailerAvailable:false
    function apiAccept(event) {return api.keys.isAccept(event);}
    function apiCancel(event) {return api.keys.isCancel(event);}
    function openTrailer() {
        if(!trailerAvailable || dataOpen || settingsOpen || rebuildPromptOpen) return false;
        trailerUrl=gameAsset(currentGame,"video");trailerTitle=gameTitleText(currentGame);
        trailerOpen=true;return true;
    }
    function closeTrailer() {
        trailerOpen=false;navZone=3;actionIndex=trailerAvailable ? 1:0;root.forceActiveFocus();
    }
    function launchCurrent() { if (currentGame) {feedback("launch");currentGame.launch();} }
    function toggleFavorite() { if (currentGame) { currentGame.favorite = !currentGame.favorite; feedback("confirm"); } }
    function openData() {
        if (!currentGame) return;
        dataConfirmation="";dataBaseline="";
        selectedGamePath = gamePath(currentGame);
        var originalFrame=frameForGame(currentGame);pendingCrop={x:originalFrame.x,y:originalFrame.y,zoom:originalFrame.zoom};
        searchRequestId++; matchRequestId++; artworkRequestId++;
        searchCompleted = false;
        matchLoading = false; artworkLoading = false;
        applyMessage = "";
        dataFocus = 0; searchKeyboardOpen = false;
        dataQuery = gameTitleText(currentGame);
        dataResults = [];
        dataResultIndex = 0;
        dataError = "";
        selectedMatch = null;artworkData={hero:[],cover:[],logo:[]};heroIndex=0;coverIndex=0;logoIndex=0;
        dataOpen = true;
        dataLoading = false;
        ensureHelper();
        var saved=gameData(currentGame);
        if(saved || metadataStatus(currentGame)==="complete" || metadataStatus(currentGame)==="manual" || gameSynopsis(currentGame).length>0) {
            var m=saved && saved.metadata ? saved.metadata : {};
            var selected={};for(var k in m) selected[k]=m[k];
            selected.title=gameTitleText(currentGame);selected.developer=gameDeveloper(currentGame);selected.summary=gameSynopsis(currentGame);
            if(!selected.publisher) selected.publisher=currentGame.publisher || "";
            if(!selected.genres) selected.genres=currentGame.genres || [];
            selectedMatch=selected;curationIndex=0;artworkEditMode=false;
            var currentAssets={hero:[],cover:[],logo:[]};
            var kinds={hero:"background",cover:"boxFront",logo:"logo"};
            for(var kind in kinds) { var url=gameAsset(currentGame,kinds[kind]);if(url) currentAssets[kind]=[{url:url,source:"existing"}]; }
            artworkData=currentAssets;heroIndex=0;coverIndex=0;logoIndex=0;
            pendingCover=activeCover;pendingCrop={x:originalFrame.x,y:originalFrame.y,zoom:originalFrame.zoom};
            Qt.callLater(function(){if(root.dataOpen && root.selectedMatch) root.openArtwork(true);dataOverlay.forceActiveFocus();});
        } else Qt.callLater(function() { focusData(0); searchInput.selectAll(); });
        dataBaseline=dataDraftSnapshot();
    }
    function selectDataMatch() {
        if (dataResults.length < 1 || dataResultIndex < 0) return;
        var item = dataResults[dataResultIndex];
        matchLoading = true;
        var requestId = ++matchRequestId;
        dataError = "";
        var xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) return;
            if (requestId !== matchRequestId || !dataOpen) return;
            matchLoading = false;
            if (xhr.status === 200) {
                try {
                    selectedMatch = JSON.parse(xhr.responseText).game;
                    curationIndex = 0;
                    artworkEditMode = false;
                    Qt.callLater(function() { root.openArtwork(); dataOverlay.forceActiveFocus(); });
                }
                catch (e) { dataError = "INVALID GAME RESPONSE"; }
            } else {
                try { dataError = JSON.parse(xhr.responseText).error || "FAILED TO LOAD MATCH"; }
                catch (e2) { dataError = "FAILED TO LOAD MATCH"; }
            }
        }
        xhr.open("GET", "http://127.0.0.1:47831/game?id=" + encodeURIComponent(item.id));
        xhr.send();
    }
    function backFromMatch() {if(applyBusy)return;if(hasDataChanges()){dataConfirmation="back";return;}backFromMatchNow();}
    function backFromMatchNow() { artworkRequestId++; artworkLoading = false; artworkEditMode = false; selectedMatch = null; focusData(dataResults.length ? 2 : 0); }
    function openArtwork(keepExisting) {
        var existing=keepExisting ? artworkData : null;
        var openingSnapshot=dataDraftSnapshot(),openingPristine=!hasDataChanges();
        if (!selectedMatch) return;
        artworkLoading = true;
        var requestId = ++artworkRequestId;
        if(!keepExisting) artworkData = ({ "hero": [], "logo": [], "cover": [] });
        dataError = "";
        artworkOpen = false;
        if(!keepExisting) {heroIndex = 0; logoIndex = 0; coverIndex = 0;}
        var xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) return;
            if (requestId !== artworkRequestId || !dataOpen || !selectedMatch) return;
            artworkLoading = false;
            if (xhr.status === 200) {
                try {
                    var found=JSON.parse(xhr.responseText).artwork;
                    if(existing) for(var kind in existing) {
                        var seen={};found[kind]=(existing[kind]||[]).concat(found[kind]||[]).filter(function(item){var url=String(item.url);if(seen[url]) return false;seen[url]=true;return true;});
                    }
                    var stillPristine=openingPristine && dataDraftSnapshot()===openingSnapshot;
                    artworkData=found;
                    if(stillPristine) dataBaseline=dataDraftSnapshot();
                }
                catch (e) { dataError = "INVALID ARTWORK RESPONSE";if(existing) artworkData=existing; }
            } else {
                try { dataError = JSON.parse(xhr.responseText).error || "FAILED TO LOAD ARTWORK"; }
                catch (e2) { dataError = "FAILED TO LOAD ARTWORK"; }
                if(existing) artworkData=existing;
            }
        }
        xhr.open("GET", "http://127.0.0.1:47831/artwork?id=" + encodeURIComponent(selectedMatch.id) + "&title=" + encodeURIComponent(selectedMatch.title || ""));
        xhr.send();
    }
    function cycleArtwork(kind, delta) {
        var arr = artworkData[kind] || [];
        if (!arr.length) return;
        if (kind === "hero") heroIndex = (heroIndex + delta + arr.length) % arr.length;
        else if (kind === "logo") logoIndex = (logoIndex + delta + arr.length) % arr.length;
        else coverIndex = (coverIndex + delta + arr.length) % arr.length;
    }
    function selectArtwork(slot) {
        if(applyBusy || artworkLoading) return;
        if(artworkEditMode && curationIndex!==slot) confirmArtworkEdit();
        curationIndex=slot; dataOverlay.forceActiveFocus();
    }
    function browseArtwork(slot,delta) {
        if(applyBusy || artworkLoading) return;
        selectArtwork(slot);
        if(!artworkEditMode) beginArtworkEdit();
        cycleArtwork(slot===0 ? "hero" : slot===1 ? "cover" : "logo",delta);
        feedback("move");
    }
    property var artworkEditOriginalCrop: ({x:50,y:50,zoom:100})
    function beginArtworkEdit() {
        if (curationIndex < 0 || curationIndex > 2) return;
        artworkEditOriginalIndex = curationIndex === 0 ? heroIndex : (curationIndex === 1 ? coverIndex : logoIndex);
        artworkEditOriginalCrop={x:pendingCrop.x,y:pendingCrop.y,zoom:pendingCrop.zoom};
        artworkEditMode = true;
    }
    function confirmArtworkEdit() { artworkEditMode = false; }
    function cancelArtworkEdit() {
        if (curationIndex === 0) heroIndex = artworkEditOriginalIndex;
        else if (curationIndex === 1) { coverIndex = artworkEditOriginalIndex;pendingCover=activeCover;pendingCrop=artworkEditOriginalCrop; }
        else if (curationIndex === 2) logoIndex = artworkEditOriginalIndex;
        artworkEditMode = false;
    }
    function gamePath(game) {
        try {
            if (!game || !game.files) return "";
            var f = game.files;
            if (f.path) return f.path;
            if (f.length !== undefined && f.length > 0) {
                var a = f[0];
                if (typeof a === "string") return a;
                if (a && a.path) return a.path;
            }
            if (f.count !== undefined && f.count > 0 && f.get) {
                var b = f.get(0);
                if (typeof b === "string") return b;
                if (b && b.path) return b.path;
            }
        } catch (e) {}
        return "";
    }
    function refreshMetadataStatus() {
        var xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE || xhr.status !== 200) return;
            try {
                var reply = JSON.parse(xhr.responseText);
                persistentMetadataStatus = reply.status || {};
                var next = {};
                for (var key in liveGameData) next[key] = liveGameData[key];
                for (var path in (reply.games || {})) {
                    if (!sessionMetadataStatus[normalizedPath(path)]) next[normalizedPath(path)] = reply.games[path];
                }
                liveGameData = next;
                api.memory.set("relay.liveGameData", next);
            } catch (e) {}
        }
        var url = "http://127.0.0.1:47831/status";
        var parts = [];
        try {
            var model = api.allGames;
            for (var i = 0; i < model.count; ++i) {
                var p = gamePath(model.get(i));
                if (p) parts.push("path=" + encodeURIComponent(p));
            }
        } catch (e) {}
        if (parts.length) url += "?" + parts.join("&");
        xhr.open("GET", url);
        xhr.send();
    }
    function currentGamePath() {
        if (selectedGamePath.length) return selectedGamePath;
        return gamePath(currentGame);
    }
    function markSessionStatus(path, status) {
        var next = {};
        for (var k in sessionMetadataStatus) next[k] = sessionMetadataStatus[k];
        var key = normalizedPath(path);
        if (status) next[key] = status; else delete next[key];
        sessionMetadataStatus = next;
        api.memory.set("relay.sessionMetadataStatus", next);
    }
    readonly property var backgroundResolutions: [720,1080,1440,2160,0]
    readonly property var backgroundResolutionLabels: ["720P","1080P","1440P","4K","ORIGINAL"]
    function changeBackgroundResolution(delta) {
        if(applyBusy) return;
        if(artworkEditMode) confirmArtworkEdit();
        curationIndex=6;setPreference("backgroundResolution",(preferences.backgroundResolution+delta+5)%5);
        dataOverlay.forceActiveFocus();
    }
    function applyMetadata() {
        if (!selectedMatch || applyBusy) return;
        var path = currentGamePath();
        if (!path) { applyMessage = "NO GAME FILE PATH AVAILABLE"; return; }
        var hero = artworkData.hero && artworkData.hero.length ? artworkData.hero[heroIndex].url : "";
        var cover = artworkData.cover && artworkData.cover.length ? artworkData.cover[coverIndex].url : "";
        var logo = artworkData.logo && artworkData.logo.length ? artworkData.logo[logoIndex].url : "";
        if(cropEditorOpen) finishCrop();
        var appliedCrop={x:pendingCrop.x,y:pendingCrop.y,zoom:pendingCrop.zoom};
        applyBusy = true; applyMessage = "APPLYING...";
        var xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) return;
            applyBusy = false;
            if (xhr.status === 200) {
                var reply;
                try { reply = JSON.parse(xhr.responseText); } catch (e) { applyMessage = "INVALID APPLY RESPONSE"; return; }
                commitCrop(appliedCrop);
                updateGameData(path, { metadata: reply.metadata || selectedMatch, assets: reply.assets || {} });
                markSessionStatus(path, "complete");
                refreshMetadataStatus();
                dataBaseline=dataDraftSnapshot();
                applyMessage = "APPLIED";
                if (reply.warnings && reply.warnings.length) {
                    applyMessage = "Metadata saved. " + reply.warnings.join(" ");
                } else {
                    selectedMatch = null; dataOpen = false; navZone = 2;
                    Qt.callLater(function() { gameRail.forceActiveFocus(); });
                }
            } else {
                try { applyMessage = JSON.parse(xhr.responseText).error || "APPLY FAILED"; }
                catch (e) { applyMessage = "APPLY FAILED"; }
            }
        }
        xhr.open("POST", "http://127.0.0.1:47831/apply");
        xhr.setRequestHeader("Content-Type", "application/json");
        xhr.send(JSON.stringify({
            path: path, metadata: selectedMatch,
            artwork: { hero: hero, cover: cover, logo: logo },
            backgroundResolution: backgroundResolutions[preferences.backgroundResolution]
        }));
    }
    function clearMetadata() {if(!applyBusy) dataConfirmation="clear";}
    function performClearMetadata() {
        if (applyBusy) return;
        var path = currentGamePath();
        if (!path) { applyMessage = "NO GAME FILE PATH AVAILABLE"; return; }
        applyBusy = true; applyMessage = "CLEARING...";
        var xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) return;
            applyBusy = false;
            if (xhr.status === 200) {
                updateGameData(path, { metadata: { title: currentGame.title, developer: "", summary: "" }, assets: { background: "", boxFront: "", logo: "" } });
                markSessionStatus(path, "missing");
                refreshMetadataStatus();
                applyMessage = "CLEARED";
                selectedMatch = null; dataOpen = false; navZone = 2;
                Qt.callLater(function() { gameRail.forceActiveFocus(); });
            } else {
                try { applyMessage = JSON.parse(xhr.responseText).error || "CLEAR FAILED"; }
                catch (e) { applyMessage = "CLEAR FAILED"; }
            }
        }
        xhr.open("POST", "http://127.0.0.1:47831/clear");
        xhr.setRequestHeader("Content-Type", "application/json");
        xhr.send(JSON.stringify({ path: path }));
    }
    function closeData() {if(applyBusy)return;if(hasDataChanges()){dataConfirmation="discard";return;}closeDataNow();}
    function closeDataNow() {
        searchRequestId++; matchRequestId++; artworkRequestId++;
        dataLoading = false; matchLoading = false; artworkLoading = false;
        metadataEditorOpen=false;cropEditorOpen=false; searchKeyboardOpen = false; navZone = 2;
        dataOpen = false;
        if (libraryDirty) {
            rebuildChoice = 0;
            rebuildPromptOpen = true;
            Qt.callLater(function() { root.forceActiveFocus(); });
        } else {
            Qt.callLater(function() { gameRail.forceActiveFocus(); });
        }
    }
    function finishRebuildPrompt() {
        rebuildPromptOpen = false;
        libraryDirty = false;
        navZone = 2;
        Qt.callLater(function() { gameRail.forceActiveFocus(); });
    }
    function searchMetadata() {
        if (!dataQuery || !dataQuery.trim().length) return;
        if (helperStarting) { helperMessage = "Starting metadata helper. Try Search in a moment."; return; }
        dataLoading = true;
        var requestId = ++searchRequestId;
        searchCompleted = false; helperMessage = "";
        dataError = "";
        dataResults = [];
        var xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) return;
            if (requestId !== searchRequestId || !dataOpen) return;
            dataLoading = false; searchCompleted = true;
            if (xhr.status === 200) {
                try {
                    dataResults = JSON.parse(xhr.responseText).results || [];
                    dataResultIndex = 0;
                    Qt.callLater(function() { root.focusData(root.dataResults.length ? 2 : 0); });
                }
                catch (e) { dataError = "INVALID RESPONSE FROM RELAY METADATA HELPER"; }
            } else {
                try { dataError = JSON.parse(xhr.responseText).error || "METADATA HELPER ERROR"; }
                catch (e2) { dataError = "Metadata helper is offline. Start START_HELPER.bat, then search again."; }
                dataResults = [];
            }
        }
        xhr.open("GET", "http://127.0.0.1:47831/search?q=" + encodeURIComponent(dataQuery));
        xhr.send();
    }

    function isSteamGame(game) {
        if (!game || !game.collections) return false;
        try {
            for (var i = 0; i < game.collections.count; ++i)
                if (game.collections.get(i).name.toLowerCase() === "steam") return true;
        } catch (e) {}
        return false;
    }
    function metadataStatus(game) {
        if (!game) return "missing";
        if (isSteamGame(game)) return "complete";
        var p = gamePath(game);
        if (p) {
            if (sessionMetadataStatus[normalizedPath(p)]) return sessionMetadataStatus[normalizedPath(p)];
            if (persistentMetadataStatus[p]) return persistentMetadataStatus[p];
            // Windows path comparison fallback: helper normalizes to lowercase forward slashes.
            var n = p.replace(/\\/g, "/").toLowerCase();
            if (persistentMetadataStatus[n]) return persistentMetadataStatus[n];
        }
        try {
            if (game.extra && (game.extra["relay-status"] === "complete" || game.extra["relay-id"])) return "complete";
            if ((game.summary || game.description) && (game.developer || game.publisher || game.genre)) return "manual";
        } catch (e) {}
        return "missing";
    }

    Component.onCompleted: {
        preferences = cleanPreferences(api.memory.get("relay.appearance"));
        settingsLoaded = true;
        splashStartupTimeout.start();
        liveGameData = api.memory.get("relay.liveGameData") || {};
        sessionMetadataStatus = api.memory.get("relay.sessionMetadataStatus") || {};
        Qt.callLater(function() { root.ensureHelper(); root.loadConfiguration(); });
    }
    Timer { id: configSaveTimer; interval: 350; onTriggered: { interval=350; root.saveConfiguration(); } }
    UISounds { id: uiSounds; transitionKind:root.preferences.transitionSound; transitionLevel:root.preferences.transitionVolume/100; pack: root.preferences.soundPack; enabled: root.preferences.sounds; level: root.preferences.soundVolume/100 }
    Timer {
        id: helperStartupTimer
        interval: 500; repeat: true
        onTriggered: {
            root.helperStartupAttempts++;
            if (root.helperStartupAttempts > 20) { stop(); root.helperStarting = false; root.helperConnection = "Offline"; root.helperMessage = "Helper could not start. Run START_HELPER.bat and check its message."; return; }
            var request = new XMLHttpRequest();
            request.onreadystatechange = function() {
                if (request.readyState !== XMLHttpRequest.DONE || request.status !== 200) return;
                helperStartupTimer.stop(); root.helperStarting = false; root.helperMessage = "";
                root.checkHelper(); root.refreshMetadataStatus(); if(root.configPending) root.saveConfiguration();
            };
            request.open("GET", "http://127.0.0.1:47831/health"); request.send();
        }
    }
    Connections {
        target: api.allGames
        onCountChanged: root.refreshMetadataStatus()
    }

    LibraryModel { id: libraryModel; sourceFilter: root.sourceIndex }
    RecentModel { id: recentModel; limit: 12; sourceFilter: root.sourceIndex }
    FavoritesModel { id: favoritesModel; sourceFilter: root.sourceIndex }

    Rectangle { anchors.fill: parent; color: "#080b0d" }

    HeroTransition {
        id: hero
        onTransitionStarted: uiSounds.transition()
        accent:root.accent
        anchors.fill: parent
        source: root.gameAsset(currentGame,"background")
        options: root.motionPreferences
        horizontalPosition: activeProvider.games.count>1 ? gameRail.currentIndex/(activeProvider.games.count-1)*2-1 : 0
        opacity: 0.95
    }

    PixelParticles {
        id:particles;anchors.left:parent.left;anchors.right:parent.right;anchors.bottom:parent.bottom
        height:parent.height;z:10000;options:root.motionPreferences;accent:root.accent;visible:!root.trailerOpen
    }

    Rectangle {
        anchors.centerIn: parent
        width: parent.height; height: parent.width
        rotation: -90
        gradient: Gradient {
            GradientStop { position: 0.00; color: "#ed07090b" }
            GradientStop { position: 0.18; color: "#d3080b0d" }
            GradientStop { position: 0.42; color: "#78080b0d" }
            GradientStop { position: 0.72; color: "#26080b0d" }
            GradientStop { position: 1.00; color: "#10080b0d" }
        }
    }
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.00; color: "#20080b0d" }
            GradientStop { position: 0.70; color: "#00080b0d" }
            GradientStop { position: 1.00; color: "#d9080b0d" }
        }
    }

    Rectangle { anchors.fill: parent; color: "black"; opacity: (100 - root.preferences.brightness) / 100 }

    Item {
    Timer { interval: 5000; running: true; repeat: true; onTriggered: root.refreshMetadataStatus() }
        anchors.fill: parent
        anchors.leftMargin: Math.max(72, parent.width * 0.055)
        anchors.rightMargin: Math.max(72, parent.width * 0.055)
        anchors.topMargin: Math.max(52, parent.height * 0.06)
        anchors.bottomMargin: Math.max(42, parent.height * 0.045)

        Text {
            id: brand
            text: "RELAY  /  PLAY"
            color: root.accent
            font.family: root.monoFont; font.pixelSize: 20 * root.textScale
            font.weight: Font.DemiBold
            font.letterSpacing: 3
        }

        OperatorMark {anchors.right:brand.left;anchors.rightMargin:14;anchors.verticalCenter:brand.verticalCenter;width:30;height:30;accent:root.accent}
        Text {anchors.left:brand.right;anchors.leftMargin:22;anchors.verticalCenter:brand.verticalCenter;text:"BY OPERATOR";color:root.menuPalette.muted;font.family:root.monoFont;font.pixelSize:11*root.textScale;font.letterSpacing:2}
        Row {
            id: tabs
            anchors.top: brand.bottom
            anchors.topMargin: 26
            spacing: 30
            ControlPrompt { owner: root; keyText: "Q"; buttons: ["lb"]; iconSize: 22; label: ""; anchors.verticalCenter: parent.verticalCenter }
            Repeater {
                model: root.tabNames
                TypewriterLabel {
                    fullText: modelData
                    active: index===root.tabIndex
                    animateTyping: false
                    characterMs: root.preferences.typewriterMs; blinkMs: root.preferences.blinkMs
                    color: index === root.tabIndex ? root.accent : (root.preferences.highContrast ? root.menuPalette.text:"#68716f")
                    font.family: root.monoFont; font.pixelSize: 21 * root.textScale
                    font.bold: index === root.tabIndex
                    font.letterSpacing: 2
                    opacity: index === root.tabIndex ? 1 : 0.8
                    Rectangle { anchors.top: parent.bottom; anchors.topMargin: 7; width: parent.width; height: 1; color: root.accent; visible: index === root.tabIndex }
                }
            }
            ControlPrompt { owner: root; keyText: "E"; buttons: ["rb"]; iconSize: 22; label: ""; anchors.verticalCenter: parent.verticalCenter }
        }

        Row {
            id: sourceFilters
            anchors.left: tabs.left
            anchors.top: tabs.bottom
            anchors.topMargin: 18
            spacing: 24
            visible: true
            Repeater {
                model: root.sourceNames
                TypewriterLabel {
                    fullText: modelData
                    active: index===root.sourceIndex
                    animateTyping: false
                    characterMs: root.preferences.typewriterMs; blinkMs: root.preferences.blinkMs
                    color: index === root.sourceIndex ? root.accent : (root.preferences.highContrast ? root.menuPalette.text:"#59615f")
                    font.family: root.monoFont; font.pixelSize: 14 * root.textScale
                    font.bold: index === root.sourceIndex
                    font.letterSpacing: 1.6
                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -8
                        onClicked: { root.observePointer();
                            root.navZone = 2;
                            root.sourceIndex = index;
                            gameRail.resetSelection();
                            gameRail.forceActiveFocus();
                        }
                    }
                }
            }
        }

        Item {
            id: heroInfo
            anchors.left: parent.left
            anchors.top: tabs.bottom
            anchors.topMargin: 78
            width: parent.width * 0.46
            height: parent.height * 0.42

            HeroDetails {
                id: heroDetails
                width: parent.width; height: Math.max(0,playActions.y-26)
                game: root.currentGame; logoSource: root.gameAsset(root.currentGame,"logo")
                title: root.currentGame ? root.gameTitleText(root.currentGame) : (root.tabIndex===2 ? "NO FAVORITES YET" : "NO GAMES")
                developerText: root.currentGame ? root.gameDeveloper(root.currentGame)+"   /   "+root.sourceNames[root.sourceIndex] : ""
                synopsis: root.gameSynopsis(root.currentGame); options: root.motionPreferences; textScale:root.textScale; fontFamily:root.monoFont
            }
            Column {
                id: playActions
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                spacing: 10
                Rectangle {
                    width: 150; height: 48; radius: 0
                    color: root.navZone === 3 && root.actionIndex===0 ? Qt.rgba(root.accent.r,root.accent.g,root.accent.b,0.12) : "#b0080e0b"
                    border.width: root.navZone === 3 && root.actionIndex===0 ? 2 : 1
                    border.color: currentGame ? root.accent : "#44504d"
                    Rectangle { id:playFlash;anchors.fill:parent;color:root.accent;opacity:0;NumberAnimation { id:playFocusFlash;target:playFlash;property:"opacity";from:root.preferences.reducedFlashes || root.preferences.reducedMotion ? 0:0.24;to:0;duration:root.preferences.animation ? 360:0;easing.type:Easing.OutCubic } }
                    TypewriterLabel { anchors.centerIn: parent; fullText: "> PLAY"; showCursor:true; cursorBlink:!root.preferences.staticCursor && !root.preferences.reducedMotion; active: root.navZone===3 && root.actionIndex===0; animateTyping: root.preferences.animation && root.preferences.typewriter && !root.preferences.reducedMotion; characterMs: root.preferences.typewriterMs; blinkMs: root.preferences.blinkMs; color: root.accent; font.family: root.monoFont; font.pixelSize: 17 * root.textScale; font.bold: true; font.letterSpacing: 1.5 }
                    MouseArea { anchors.fill: parent; onClicked: { root.observePointer(); root.navZone = 3; root.actionIndex = 0; root.launchCurrent(); } }
                }
                Rectangle {
                    objectName:"relayTrailerButton";width:150;height:40;visible:root.trailerAvailable
                    color:root.navZone===3 && root.actionIndex===1 ? root.menuPalette.selectedFill:root.menuPalette.surface
                    border.width:root.navZone===3 && root.actionIndex===1 ? 2:1;border.color:root.accent
                    Text {anchors.centerIn:parent;text:root.keyboardHints ? "TRAILER [T]":"TRAILER";color:root.accent;font.family:root.monoFont;font.pixelSize:14*root.textScale}
                    MouseArea {anchors.fill:parent;onClicked:{root.observePointer();root.openTrailer()}}
                }
                Text {
                    text: currentGame && root.metadataStatus(currentGame) === "missing" ? "METADATA MISSING" : ""
                    visible: text.length > 0
                    color: "#b9a66d"; font.family: root.monoFont; font.pixelSize: 12 * root.textScale; font.letterSpacing: 1.2
                }
            }
        }

        Text {
            id: emptyText
            anchors.left: parent.left
            anchors.bottom: gameRail.top
            anchors.bottomMargin: 24
            visible: activeProvider.games.count === 0
            text: tabIndex === 2 ? "Use FAVORITE to add games here." : (tabIndex === 0 ? "Played games will appear here." : "No games available in this view.")
            color: "#7e8885"
            font.family: root.monoFont; font.pixelSize: 18 * root.textScale
        }

        Rectangle {
            objectName:"relayTrack"
            anchors.left: parent.left; anchors.right: parent.right; anchors.leftMargin: -40; anchors.rightMargin: -40
            y: gameRail.y; height: gameRail.height
            color: "#080d0b"; opacity: root.preferences.trackOpacity/100
            Rectangle { anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; height: 1; color: root.accent; opacity: 0.3 }
            Rectangle { anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom; height: 1; color: root.accent; opacity: 0.3 }
        }
        GameRail {
            fontFamily:root.monoFont
            id: gameRail
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: help.top
            anchors.bottomMargin: 26
            gameModel: activeProvider.games
            currentGame: root.currentGame
            modalOpen: root.splashOpen || root.dataOpen || root.rebuildPromptOpen || root.settingsOpen || root.trailerOpen
            navigationActive: root.navZone === 2
            accent: root.accent
            textScale: root.textScale
            animationEnabled: root.preferences.animation && !root.preferences.reducedMotion
            options: root.motionPreferences
            onNavigationSound: { root.feedback(direction<0 ? "left":"right");particles.sway(direction); }
            inputObserver: root.observeInput
            pointerObserver:root.observePointer
            settingsShortcut: root.openSettings
            statusResolver: root.metadataStatus
            artworkResolver: root.gameAsset
            titleResolver: root.gameTitleText
            frameResolver: root.frameForGame
            focus: !root.splashOpen && root.navZone === 2 && !root.dataOpen && !root.rebuildPromptOpen && !root.settingsOpen
            onSelectionRequested: root.navZone = 2
            onActivated: { root.navZone = 3; root.actionIndex = 0; root.forceActiveFocus(); }
            onFavoriteRequested: root.toggleFavorite()
            onPreviousTabRequested: root.changeTab(-1)
            onNextTabRequested: root.changeTab(1)
            onSourceFilterRequested: root.changeSource(1)
            onPreviousSourceRequested: root.changeSource(-1)
            onMetadataRequested: root.openData()
            onActionsRequested: { root.navZone = 3; root.actionIndex = 0; root.forceActiveFocus(); }
            onUpperNavigationRequested: { root.navZone = 3; root.forceActiveFocus(); }
        }

        Text {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            text: activeProvider.games.count > 0 ? ((gameRail.currentIndex + 1) + "  /  " + activeProvider.games.count) : "0  /  0"
            color: "#68726f"
            font.family: root.monoFont; font.pixelSize: 14 * root.textScale
            font.letterSpacing: 1.8
        }

        Item {
            id: help
            anchors.left: parent.left; anchors.right: parent.right; anchors.rightMargin: 94
            anchors.bottom: parent.bottom; height: Math.max(32, 32 * root.textScale)
            Row {
                scale: Math.min(1, parent.width / (promptWidth + 108))
                transformOrigin: Item.TopLeft
                width: parent.width / scale
                spacing: Math.max(12, (width - promptWidth) / 6)
                property real promptWidth: selectHint.width + favoriteHint.width + categoryHint.width + sourceHint.width + metadataHint.width + backHint.width + settingsHint.width
                ControlPrompt { id: selectHint; owner: root; keyText: "ENTER"; buttons: root.promptButtons("accept"); label: "SELECT" }
                ControlPrompt { id: favoriteHint; owner: root; keyText: "F"; buttons: root.promptButtons("details"); label: "FAVORITE" }
                ControlPrompt { id: categoryHint; owner: root; keyText: "Q/E"; buttons: root.promptButtons("category"); label: "CATEGORY" }
                ControlPrompt { id: sourceHint; owner: root; keyText: "TAB"; buttons: root.promptButtons("source"); label: "SOURCE" }
                ControlPrompt { id: metadataHint; owner: root; keyText: "BACKSPACE"; buttons: root.promptButtons("filters"); label: "METADATA" }
                ControlPrompt { id: backHint; owner: root; keyText: "ESC"; buttons: root.promptButtons("cancel"); label: "BACK" }
                ControlPrompt { id: settingsHint; owner: root; keyText: "S"; buttons: root.promptButtons("settings"); label: "SETTINGS" }
            }
        }
        Text { anchors.right: parent.right; anchors.top: brand.top; text: "SETTINGS"; color: root.accent; font.family: root.monoFont; font.pixelSize: 14 * root.textScale; MouseArea { anchors.fill: parent; anchors.margins: -12; onClicked: { root.observePointer();root.openSettings() }} }
        Rectangle { anchors.left: parent.left; anchors.right: parent.right; anchors.top: brand.bottom; anchors.topMargin: 10; height: 1; color: root.accent; opacity: 0.22 }
    }

    Loader {
        id:trailerLoader;objectName:"relayTrailerLoader";anchors.fill:parent;z:20000
        active:root.trailerOpen;source:"components/TrailerPlayer.qml"
        onLoaded:{item.owner=root;item.start(root.trailerUrl,root.trailerTitle);item.forceActiveFocus();}
    }
    Connections {target:trailerLoader.item;ignoreUnknownSignals:true;onClosed:root.closeTrailer()}
    SettingsPanel { id: settingsPanel; anchors.fill: parent; z: 100; visible: root.settingsOpen; owner: root }

    Rectangle {
        id: dataOverlay
        anchors.fill: parent
        visible: root.dataOpen
        color: root.menuPalette.backdrop
        z: 1000
        focus: visible

        // Modal input shield: nothing behind DATA can receive mouse input.
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.AllButtons
            onClicked: { root.observePointer();}
            onWheel: wheel.accepted = true
        }

        Rectangle {
            id: dataPanel
            anchors.fill: parent
            anchors.margins: Math.max(58, parent.width * 0.055)
            color: root.menuPalette.panel
            border.width: 1
            border.color: root.accent

            Item {
                anchors.fill: parent
                anchors.margins: 42

                Text {
                    id: dataHeader
                    text: "RELAY / GAME DATA"
                    color: root.accent
                    font.family: root.monoFont; font.pixelSize: 24 * root.textScale
                    font.weight: Font.DemiBold
                    font.letterSpacing: 2
                }
                Text {
                    anchors.left: dataHeader.left
                    anchors.top: dataHeader.bottom
                    anchors.topMargin: 10
                    text: root.gameTitleText(root.currentGame)
                    color: root.menuPalette.muted
                    font.family: root.monoFont; font.pixelSize: 15 * root.textScale
                }

                Rectangle {
                    id: closeButton
                    anchors.right: parent.right
                    anchors.top: parent.top
                    width: 42; height: 42
                    color: root.dataFocus === 4 || closeMouse.containsMouse ? root.menuPalette.selectedFill : "transparent"
                    border.width: 1
                    border.color: root.dataFocus === 4 ? root.accent : root.menuPalette.line
                    Text { anchors.centerIn: parent; text: "X"; color: root.menuPalette.text; font.family: root.monoFont; font.pixelSize: 24 * root.textScale }
                    MouseArea {
                        id: closeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: { root.observePointer();root.closeData() }
                    }
                }

                Rectangle {
                    anchors.left: parent.left; anchors.right: parent.right
                    anchors.top: dataHeader.bottom; anchors.topMargin: 42
                    height: 1; color: root.menuPalette.line
                }

                Rectangle {
                    anchors.right: closeButton.left; anchors.rightMargin: 12; anchors.top: parent.top
                    id: clearTopButton
                    width: 170; height: 42
                    color: root.dataFocus === 3 || clearTopMouse.containsMouse ? root.menuPalette.selectedFill : "transparent"
                    border.width: 1; border.color: root.dataFocus === 3 ? root.accent : root.menuPalette.line
                    Text { anchors.centerIn: parent; text: "CLEAR METADATA"; color: root.menuPalette.text; font.family: root.monoFont; font.pixelSize: 12 * root.textScale; font.bold: true; font.letterSpacing: 1 }
                    MouseArea { id: clearTopMouse; anchors.fill: parent; hoverEnabled: true; enabled: !root.applyBusy; onClicked: { root.observePointer();root.clearMetadata() }}
                }

                Text {
                    id: searchCaption
                    anchors.left: parent.left
                    anchors.top: dataHeader.bottom
                    anchors.topMargin: 72
                    text: "SEARCH"
                    color: root.menuPalette.muted
                    font.family: root.monoFont; font.pixelSize: 12 * root.textScale
                    font.bold: true
                    font.letterSpacing: 1.8
                }

                Rectangle {
                    id: searchBox
                    anchors.left: parent.left
                    anchors.top: searchCaption.bottom
                    anchors.topMargin: 10
                    width: Math.min(parent.width * 0.58, 720)
                    height: 48
                    color: root.menuPalette.surface
                    border.width: searchInput.activeFocus ? 1 : 1
                    border.color: root.dataFocus === 0 ? root.accent : root.menuPalette.line

                    TextInput {
                        id: searchInput
                    enabled: root.selectedMatch === null
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 16
                        verticalAlignment: TextInput.AlignVCenter
                        text: root.dataQuery
                        color: root.menuPalette.text
                        selectionColor: root.menuPalette.selectedFill
                        selectedTextColor: "#ffffff"
                        font.family: root.monoFont; font.pixelSize: 17 * root.textScale
                        clip: true
                        selectByMouse: true
                        onTextChanged: root.dataQuery = text
                        onActiveFocusChanged: if (activeFocus) root.dataFocus = 0
                        Keys.onPressed: root.handleDataKey(event)
                    }
                }

                Rectangle {
                    id: searchButton
                    anchors.left: searchBox.right
                    anchors.leftMargin: 10
                    anchors.top: searchBox.top
                    width: 112; height: searchBox.height
                    color: root.dataFocus === 1 || searchMouse.containsMouse ? root.menuPalette.selectedFill : root.menuPalette.selectedFill
                    border.width: 1; border.color: root.dataFocus === 1 ? root.accent : root.menuPalette.line
                    Text { anchors.centerIn: parent; text: "SEARCH"; color: root.menuPalette.text; font.family: root.monoFont; font.pixelSize: 13 * root.textScale; font.bold: true; font.letterSpacing: 1.2 }
                    MouseArea {
                        id: searchMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: { root.observePointer();root.searchMetadata() }
                    }
                }

                Text {
                    anchors.left: parent.left
                    anchors.top: searchBox.bottom
                    anchors.topMargin: 18
                    visible: root.dataLoading
                    text: "SEARCHING RELAY METADATA HELPER..."
                    color: root.menuPalette.muted; font.family: root.monoFont; font.pixelSize: 14 * root.textScale; font.letterSpacing: 1.2
                }
                Text {
                    anchors.left: parent.left
                    anchors.top: searchBox.bottom
                    anchors.topMargin: 18
                    width: parent.width
                    wrapMode: Text.Wrap
                    visible: root.dataError.length > 0 || root.helperMessage.length > 0 || (root.searchCompleted && !root.dataLoading && !root.dataResults.length)
                    text: root.dataError || root.helperMessage || "No matches found. Try a shorter title without the edition name."
                    color: "#b9a66d"; font.family: root.monoFont; font.pixelSize: 15 * root.textScale; font.letterSpacing: 1.2
                }

                ListView {
                    id: resultList
                    anchors.left: parent.left; anchors.right: parent.right
                    anchors.top: searchBox.bottom; anchors.topMargin: 48
                    anchors.bottom: dataHelp.top; anchors.bottomMargin: 28
                    model: root.dataResults
                    currentIndex: root.dataResultIndex
                    spacing: 4; clip: true
                    delegate: Rectangle {
                        width: resultList.width; height: 64
                        color: index === root.dataResultIndex && root.dataFocus === 2 ? root.menuPalette.selectedFill : "transparent"
                        Rectangle { width: 2; height: parent.height; color: index === root.dataResultIndex ? root.accent : "transparent" }
                        Text { anchors.left: parent.left; anchors.leftMargin: 20; anchors.verticalCenter: parent.verticalCenter; text: modelData.title || "UNKNOWN"; color: root.dataFocus===2 && index===root.dataResultIndex ? root.accent : root.menuPalette.text; font.family: root.monoFont; font.pixelSize: 18 * root.textScale }
                        Text { anchors.right: parent.right; anchors.rightMargin: 20; anchors.verticalCenter: parent.verticalCenter; text: (modelData.year || "") + (modelData.developer ? "   /   " + modelData.developer : ""); color: root.menuPalette.muted; font.family: root.monoFont; font.pixelSize: 14 * root.textScale }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: { root.observePointer(); root.dataResultIndex = index; root.focusData(2); }
                            onDoubleClicked: { root.dataResultIndex = index; root.selectDataMatch(); }
                        }
                    }
                }

                Rectangle {
                    id: curationView
                    anchors.fill: parent
                    color: root.menuPalette.surface
                    visible: root.selectedMatch !== null
                    z: 30

                    Rectangle {
                        anchors.right: parent.right; anchors.top: parent.top
                        width: 34; height: 34; color: root.curationIndex === 5 || closeCurate.containsMouse ? root.menuPalette.selectedFill : "transparent"
                        border.width: root.curationIndex === 5 ? 1 : 0; border.color: root.accent
                        Text { anchors.centerIn: parent; text: "X"; color: root.menuPalette.text; font.family: root.monoFont; font.pixelSize: 22 * root.textScale }
                        MouseArea { id: closeCurate; anchors.fill: parent; hoverEnabled: true; onClicked: { root.observePointer();root.backFromMatch() }}
                    }

                    Text {
                        id: curateKicker
                        anchors.left: parent.left; anchors.top: parent.top
                        text: "RELAY / GAME DATA / MATCH"
                        color: root.accent; font.family: root.monoFont; font.pixelSize: 12 * root.textScale; font.bold: true; font.letterSpacing: 1.8
                    }

                    Item {
                        anchors.left: parent.left; anchors.right: parent.right
                        anchors.top: curateKicker.bottom; anchors.topMargin: 20
                        anchors.bottom: curateFooter.top; anchors.bottomMargin: 24

                        Item {
                            id: metaPane
                            Row {
                                anchors.left:parent.left;anchors.bottom:parent.bottom;spacing:20
                                Item { width:editTextCue.width;height:editTextCue.height;ControlPrompt { id:editTextCue;owner:root;keyText:"F2";buttons:root.promptButtons("details");label:"EDIT TEXT" } MouseArea { anchors.fill:parent;enabled:!root.applyBusy;onClicked: { root.observePointer();root.openMetadataEditor() }} }
                                Item { width:findArtCue.width;height:findArtCue.height;ControlPrompt { id:findArtCue;owner:root;keyText:"F3";buttons:["rb"];label:"REFRESH ARTWORK" } MouseArea { anchors.fill:parent;enabled:!root.applyBusy;onClicked: { root.observePointer();root.openArtwork(true) }} }
                            }
                            anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom
                            width: parent.width * 0.39

                            Text {
                                id: curateTitle
                                anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                                text: root.selectedMatch ? root.selectedMatch.title : ""
                                color: root.menuPalette.text; font.family: root.monoFont; font.pixelSize: 30 * root.textScale; font.weight: Font.DemiBold; wrapMode: Text.Wrap
                            }
                            Text {
                                id: curateSub
                                anchors.left: parent.left; anchors.top: curateTitle.bottom; anchors.topMargin: 9
                                text: root.selectedMatch ? ((root.selectedMatch.developer || "UNKNOWN DEVELOPER") + (root.selectedMatch.year ? "   /   " + root.selectedMatch.year : "")) : ""
                                color: root.menuPalette.muted; font.family: root.monoFont; font.pixelSize: 14 * root.textScale
                            }
                            Rectangle { id: metaRule; anchors.left: parent.left; anchors.right: parent.right; anchors.top: curateSub.bottom; anchors.topMargin: 20; height: 1; color: root.menuPalette.line }

                            Column {
                                id: metaFields
                                anchors.left: parent.left; anchors.right: parent.right
                                anchors.top: metaRule.bottom; anchors.topMargin: 20
                                spacing: 14
                                Text { width: parent.width; text: "DEVELOPER\n" + (root.selectedMatch && root.selectedMatch.developer ? root.selectedMatch.developer : "-"); color: root.menuPalette.text; font.family: root.monoFont; font.pixelSize: 14 * root.textScale; lineHeight: 1.35 }
                                Text { width: parent.width; text: "PUBLISHER\n" + (root.selectedMatch && root.selectedMatch.publisher ? root.selectedMatch.publisher : "-"); color: root.menuPalette.text; font.family: root.monoFont; font.pixelSize: 14 * root.textScale; lineHeight: 1.35 }
                                Text { width: parent.width; text: "GENRES\n" + (root.selectedMatch && root.selectedMatch.genres ? root.selectedMatch.genres.join(" / ") : "-"); color: root.menuPalette.text; font.family: root.monoFont; font.pixelSize: 14 * root.textScale; lineHeight: 1.35; wrapMode: Text.Wrap }
                                Text {
                                    width: parent.width
                                    text: "SYNOPSIS\n" + (root.selectedMatch && root.selectedMatch.summary ? root.selectedMatch.summary : "No synopsis available.")
                                    color: root.menuPalette.text; font.family: root.monoFont; font.pixelSize: 13 * root.textScale; lineHeight: 1.35
                                    wrapMode: Text.Wrap; maximumLineCount: 8; elide: Text.ElideRight
                                }
                            }
                        }

                        Rectangle {
                            anchors.left: metaPane.right; anchors.leftMargin: 28
                            anchors.top: parent.top; anchors.bottom: parent.bottom
                            width: 1; color: root.menuPalette.line
                        }

                        Item {
                            id: artPane
                            anchors.left: metaPane.right; anchors.leftMargin: 58
                            anchors.right: parent.right; anchors.top: parent.top; anchors.bottom: parent.bottom

                            Text {
                                id: artStatus
                                anchors.left: parent.left; anchors.top: parent.top
                                text: root.artworkEditMode ? ("ADJUSTING " + (root.curationIndex === 0 ? "HERO" : (root.curationIndex === 1 ? "COVER" : "LOGO")) + " ARTWORK") : "ARTWORK"
                                color: root.menuPalette.text; font.family: root.monoFont; font.pixelSize: 13 * root.textScale; font.bold: true; font.letterSpacing: 1.4
                            }
                            Rectangle {
                                objectName:"backgroundResolutionPicker"
                                anchors.right:parent.right;anchors.verticalCenter:artStatus.verticalCenter
                                width:Math.min(parent.width*.58,410);height:30
                                color:root.curationIndex===6 ? root.menuPalette.selectedFill:"transparent"
                                border.width:root.curationIndex===6 ? 1:0;border.color:root.accent
                                Text {anchors.centerIn:parent;text:"BACKGROUND LIMIT  <  "+root.backgroundResolutionLabels[root.preferences.backgroundResolution]+"  >";color:root.accent;font.family:root.monoFont;font.pixelSize:12*root.textScale}
                                MouseArea {anchors.left:parent.left;width:parent.width/2;height:parent.height;enabled:!root.applyBusy;onClicked:root.changeBackgroundResolution(-1)}
                                MouseArea {anchors.right:parent.right;width:parent.width/2;height:parent.height;enabled:!root.applyBusy;onClicked:root.changeBackgroundResolution(1)}
                            }
                            ArtworkPicker {
                                id:heroPreview;objectName:"heroArtworkPicker";owner:root;kind:"hero";slot:0;label:"HERO ARTWORK";crop:true
                                anchors.left:parent.left;anchors.right:parent.right;anchors.top:artStatus.bottom;anchors.topMargin:12
                                height:Math.min(width*9/16,parent.height*0.58)
                            }
                            Row {
                                anchors.left:parent.left;anchors.right:parent.right;anchors.top:heroPreview.bottom;anchors.topMargin:14
                                anchors.bottom:parent.bottom;spacing:20
                                ArtworkPicker { objectName:"coverArtworkPicker";owner:root;kind:"cover";slot:1;label:"COVER ARTWORK";width:(parent.width-parent.spacing)/2;height:parent.height }
                                ArtworkPicker { objectName:"logoArtworkPicker";owner:root;kind:"logo";slot:2;label:"LOGO ARTWORK";width:(parent.width-parent.spacing)/2;height:parent.height }
                            }
                        }
                    }

                    Item {
                        anchors.right:parent.right;width:parent.width*0.56;anchors.verticalCenter:curateFooter.verticalCenter;height:40
                        Row {
                            anchors.centerIn:parent;width:parent.width
                            property real total:navHint.width+openHint.width+cropHint.width+cancelHint.width
                            spacing:Math.max(12,(width-total)/3)
                            ControlPrompt { id:navHint;owner:root;keyText:"ARROWS";buttons:root.promptButtons("navigate");label:root.artworkEditMode ? "BROWSE":"SELECT" }
                            ControlPrompt { id:openHint;owner:root;keyText:"ENTER";buttons:root.promptButtons("accept");label:root.artworkEditMode ? "CONFIRM":"OPEN" }
                            ControlPrompt { id:cropHint;owner:root;keyText:"BACKSPACE";buttons:root.promptButtons("filters");label:"CROP";opacity:root.curationIndex===1 ? 1:0.4 }
                            ControlPrompt { id:cancelHint;owner:root;keyText:"ESC";buttons:root.promptButtons("cancel");label:root.artworkEditMode ? "CANCEL":"BACK" }
                        }
                    }
                    Row {
                        id: curateFooter
                        anchors.left: parent.left; anchors.bottom: parent.bottom
                        spacing: 26
                        Rectangle {
                            width: 150; height: 46; color: root.curationIndex === 3 || applyMouse.containsMouse ? root.menuPalette.selectedFill : "transparent"
                            border.width: 1; border.color: root.accent
                            Text { anchors.centerIn: parent; text: root.applyBusy ? "WORKING..." : "APPLY"; color: root.accent; font.family: root.monoFont; font.pixelSize: 14 * root.textScale; font.bold: true; font.letterSpacing: 1.2 }
                            MouseArea { id: applyMouse; anchors.fill: parent; hoverEnabled: true; enabled: !root.applyBusy; onClicked: { root.observePointer();root.applyMetadata() }}
                        }
                        Rectangle {
                            width: 170; height: 46; color: root.curationIndex === 4 || clearMouse.containsMouse ? root.menuPalette.selectedFill : root.menuPalette.surface; border.width: 1; border.color: root.curationIndex === 4 ? root.accent : root.menuPalette.line
                            Text { anchors.centerIn: parent; text: "CLEAR METADATA"; color: root.menuPalette.text; font.family: root.monoFont; font.pixelSize: 13 * root.textScale; font.bold: true; font.letterSpacing: 1.0 }
                            MouseArea { id: clearMouse; anchors.fill: parent; hoverEnabled: true; enabled: !root.applyBusy; onClicked: { root.observePointer();root.clearMetadata() }}
                        }
                        Text { anchors.verticalCenter: parent.verticalCenter; text: root.applyMessage; visible: text.length > 0; color: root.menuPalette.muted; font.family: root.monoFont; font.pixelSize: 12 * root.textScale }

                    }
                }

                Row {
                    id: dataHelp
                    anchors.left: parent.left; anchors.bottom: parent.bottom
                    spacing: 30
                    ControlPrompt { owner: root; keyText: "ENTER"; buttons: root.promptButtons("accept"); label: "SELECT" }
                    ControlPrompt { owner: root; keyText: "ARROWS"; buttons: root.promptButtons("navigate"); label: "NAVIGATE" }
                    ControlPrompt { owner: root; keyText: "ESC"; buttons: root.promptButtons("cancel"); label: "BACK" }
                }
            }
        }

        Rectangle {
            anchors.fill: parent
            visible: root.searchKeyboardOpen
            z: 100
            color: root.menuPalette.panel
            MouseArea { anchors.fill: parent; onClicked: { root.observePointer();} }
            Column {
                anchors.centerIn: parent
                spacing: 24
                Text { text: root.metadataEditorOpen ? "EDIT METADATA FIELD" : "EDIT SEARCH"; color: root.menuPalette.text; font.family: root.monoFont; font.pixelSize: 24 * root.textScale; font.bold: true }
                Text { text: root.dataQuery; width: 800; elide: Text.ElideLeft; color: root.menuPalette.text; font.family: root.monoFont; font.pixelSize: 22 * root.textScale }
                Grid {
                    columns: 8; spacing: 10
                    Repeater {
                        model: root.searchKeyboardKeys
                        Rectangle {
                            width: 92; height: 52
                            color: index === root.searchKeyboardIndex ? root.menuPalette.selectedFill : "transparent"
                            border.width: 1; border.color: index===root.searchKeyboardIndex ? root.accent : root.menuPalette.line
                            Text { anchors.centerIn: parent; text: modelData; color: index === root.searchKeyboardIndex ? root.accent : root.menuPalette.text; font.family: root.monoFont; font.pixelSize: 15 * root.textScale }
                            MouseArea { anchors.fill: parent; onClicked: { root.observePointer(); root.searchKeyboardIndex = index; root.useSearchKeyboardKey(); } }
                        }
                    }
                }
                Row { spacing: 28
                    ControlPrompt { owner: root; keyText: "ARROWS"; buttons: root.promptButtons("navigate"); label: "MOVE" }
                    ControlPrompt { owner: root; keyText: "ENTER"; buttons: root.promptButtons("accept"); label: "TYPE" }
                    ControlPrompt { owner: root; keyText: "ESC"; buttons: root.promptButtons("cancel"); label: "BACK" }
                }
            }
        }
        MetadataEditor { id:metadataEditor;anchors.fill:parent;z:95;visible:root.metadataEditorOpen;owner:root }
        ThumbnailCropEditor { anchors.fill:parent; z:110; visible:root.cropEditorOpen;owner:root }
        Keys.onPressed: root.handleDataKey(event)

        onVisibleChanged: {
            if (visible) {
                forceActiveFocus();
                Qt.callLater(function() {
                    if (root.selectedMatch === null) { root.focusData(0); searchInput.selectAll(); }
                    else dataOverlay.forceActiveFocus();
                });
            }
        }
    }

    Rectangle {
        id: rebuildPrompt
        anchors.fill: parent
        visible: root.rebuildPromptOpen
        z: 200
        color: "#d9080b0d"

        Rectangle {
            anchors.centerIn: parent
            width: Math.min(620, parent.width * 0.48)
            height: 260
            color: "#0d1215"
            border.width: 1; border.color: "#35413e"

            Text { anchors.left: parent.left; anchors.top: parent.top; anchors.margins: 30; text: "LIBRARY CHANGED"; color: "#edf1ef"; font.family: root.monoFont; font.pixelSize: 24 * root.textScale; font.bold: true }
            Text { anchors.left: parent.left; anchors.top: parent.top; anchors.topMargin: 78; anchors.leftMargin: 30; text: "Metadata or artwork changed. Reload Pegasus files now?"; color: "#9da7a4"; font.family: root.monoFont; font.pixelSize: 15 * root.textScale }

            Row {
                anchors.left: parent.left; anchors.bottom: parent.bottom; anchors.margins: 30; spacing: 16
                Rectangle {
                    width: 210; height: 48
                    color: root.rebuildChoice === 0 ? "#e5ebe8" : "#141b1e"
                    border.width: root.rebuildChoice === 0 ? 3 : 1; border.color: root.rebuildChoice === 0 ? root.accent : "#44504d"
                    Text { anchors.centerIn: parent; text: "REBUILD LIBRARY"; color: root.rebuildChoice === 0 ? "#111514" : "#aeb7b4"; font.family: root.monoFont; font.pixelSize: 13 * root.textScale; font.bold: true }
                    MouseArea { anchors.fill: parent; onClicked: { root.observePointer(); root.rebuildChoice = 0; var rx = new XMLHttpRequest(); rx.onreadystatechange = function() { if (rx.readyState === XMLHttpRequest.DONE) root.finishRebuildPrompt(); }; rx.open("POST", "http://127.0.0.1:47831/reload"); rx.send(); } }
                }
                Rectangle {
                    width: 130; height: 48
                    color: root.rebuildChoice === 1 ? "#e5ebe8" : "#141b1e"
                    border.width: root.rebuildChoice === 1 ? 3 : 1; border.color: root.rebuildChoice === 1 ? root.accent : "#44504d"
                    Text { anchors.centerIn: parent; text: "LATER"; color: root.rebuildChoice === 1 ? "#111514" : "#aeb7b4"; font.family: root.monoFont; font.pixelSize: 13 * root.textScale; font.bold: true }
                    MouseArea { anchors.fill: parent; onClicked: { root.observePointer();root.finishRebuildPrompt() }}
                }
            }
        }
    }

    Keys.onPressed: {
        root.observeInput(event);
        if(root.dataConfirmation.length) {event.accepted=true;return;}
        if(root.splashOpen || root.trailerOpen) {event.accepted=true;return;}
        if(event.key===Qt.Key_T && !root.dataOpen && !root.settingsOpen && !root.rebuildPromptOpen) {event.accepted=true;if(!event.isAutoRepeat) root.openTrailer();return;}
        if (!root.dataOpen && !root.settingsOpen && !root.rebuildPromptOpen && event.key===Qt.Key_F) { event.accepted=true; if(!event.isAutoRepeat) root.toggleFavorite(); return; }
        if (root.settingsOpen) { event.accepted = true; return; }
        if (root.rebuildPromptOpen) {
            if (event.key === Qt.Key_Left || event.key === Qt.Key_Right) {
                event.accepted = true; root.rebuildChoice = root.rebuildChoice === 0 ? 1 : 0;
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || api.keys.isAccept(event)) {
                event.accepted = true;
                if (root.rebuildChoice === 0) {
                    var rx = new XMLHttpRequest();
                    rx.onreadystatechange = function() { if (rx.readyState === XMLHttpRequest.DONE) root.finishRebuildPrompt(); }
                    rx.open("POST", "http://127.0.0.1:47831/reload"); rx.send();
                } else root.finishRebuildPrompt();
            } else if (event.key === Qt.Key_Escape || api.keys.isCancel(event)) {
                event.accepted = true; root.finishRebuildPrompt();
            }
            return;
        }
        if (root.dataOpen) return;


        if (event.key === Qt.Key_Up) {
            event.accepted = true; root.navUp();
        } else if (event.key === Qt.Key_Down) {
            event.accepted = true; root.navDown();
        } else if (event.key === Qt.Key_Left || event.key === Qt.Key_Right) {
            event.accepted = true;
            if(root.navZone===3 && root.trailerAvailable) {root.actionIndex=1-root.actionIndex;root.feedback("move");}
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            event.accepted = true; root.activateZone();
        } else if (event.key === Qt.Key_Backspace || (event.key>=1048576 && event.key<=1048588 && api.keys.isFilters(event))) {
            event.accepted = true; if (!event.isAutoRepeat) root.openData();
        } else if (event.key === Qt.Key_F || (event.key>=1048576 && event.key<=1048588 && api.keys.isDetails(event))) {
            event.accepted = true; if (!event.isAutoRepeat) root.toggleFavorite();
        } else if (api.keys.isAccept(event) && !event.isAutoRepeat) {
            event.accepted = true; root.activateZone();
        } else if (event.key === Qt.Key_Q || event.key === 1048580) {
            event.accepted = true; if (!event.isAutoRepeat) root.moveTab(-1);
        } else if (event.key === Qt.Key_E || event.key === 1048583) {
            event.accepted = true; if (!event.isAutoRepeat) root.moveTab(1);
        } else if (event.key === Qt.Key_Tab || event.key === 1048584 || event.key === 1048581) {
            event.accepted = true; if (!event.isAutoRepeat) root.moveSource(event.key === 1048581 || (event.modifiers & Qt.ShiftModifier) ? -1 : 1);
        } else if (event.key === Qt.Key_S || event.key === Qt.Key_F1 || event.key === 1048582) {
            event.accepted = true; if (!event.isAutoRepeat) root.openSettings();
        }
    }

    // IMPORTANT: Do not consume api.keys.isCancel() here.
    // Pegasus owns the global Back/Escape action and uses it to open its
    // native main menu (Settings, Help, Quit, etc.). Leaving Cancel
    // unhandled allows the event to propagate out of the theme.
    ColourNameEditor { id:colourNameEditor;anchors.fill:parent;z:12000;visible:root.colourEditorOpen;owner:root;onVisibleChanged:if(visible) begin() }

    ColourConfirmation {anchors.fill:parent;z:13000;owner:root;visible:root.colourConfirmation.length>0;onVisibleChanged:if(visible) {selected=0;forceActiveFocus();}}

}





