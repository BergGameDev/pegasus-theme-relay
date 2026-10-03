import QtQuick 2.5
FocusScope {
    id: panel
    objectName: "relaySettings"
    property var owner
    property int selected: 0
    property bool developer: false
    property bool previewDim: false
    property int savedColourIndex:0
    property int heldDirection:0
    property int heldSelection:-1
    property double heldSince:0
    function stopAdjustHold(){adjustHold.stop();heldDirection=0;}
    function beginAdjustHold(delta){
        stopAdjustHold();change(delta);
        heldDirection=delta;heldSelection=selected;heldSince=Date.now();adjustHold.interval=350;adjustHold.start();
    }
    function holdMultiplier(elapsed){return elapsed<800 ? 1:elapsed<1600 ? 2:elapsed<2600 ? 5:elapsed<4000 ? 10:20;}
    Timer {
        id:adjustHold;repeat:true
        onTriggered:{
            if(!panel.visible || !panel.activeFocus || panel.selected!==panel.heldSelection){panel.stopAdjustHold();return;}
            var row=panel.rows[panel.selected],elapsed=Date.now()-panel.heldSince;
            var numeric=row && row.min!==undefined && !row.choices && !row.toggle && !row.action;
            panel.change(panel.heldDirection,numeric ? panel.holdMultiplier(elapsed):1);
            interval=numeric ? 65:220;
        }
    }
    onVisibleChanged:if(!visible) stopAdjustHold()
    onActiveFocusChanged:if(!activeFocus) stopAdjustHold()
    readonly property var appearanceRows: [
    {"name":"AUTO-START ARTWORK HELPER","section":"OPTIONAL HELPER","key":"helperAutoStart","toggle":true},
    {"name":"STARTUP SPLASH","section":"STARTUP","key":"startupSplash","toggle":true},
    {"name":"WAIT FOR INPUT","key":"splashWait","toggle":true},
    {
        "name": "ACCENT COLOUR",
        "section": "COLOUR",
        "key": "accent",
        "choices": panel.owner.accentNames
    },
    {
        "name": "CUSTOM RED",
        "key": "red",
        "min": 0,
        "max": 255,
        "step": 8,
        "custom": true
    },
    {
        "name": "CUSTOM GREEN",
        "key": "green",
        "min": 0,
        "max": 255,
        "step": 8,
        "custom": true
    },
    {
        "name": "CUSTOM BLUE",
        "key": "blue",
        "min": 0,
        "max": 255,
        "step": 8,
        "custom": true
    },
    {
        "name": "SAVE NAMED COLOUR",
        "action": "saveColour"
    },
    {
        "name": "REMOVE SELECTED COLOUR",
        "action": "removeColour"
    },
    {
        "name": "CONTROL PROMPTS",
        "section": "CONTROLS",
        "key": "prompts",
        "choices": [
            "AUTO",
            "KEYBOARD",
            "XBOX",
            "PLAYSTATION"
        ]
    },
    {
        "name": "TEXT SIZE",
        "section": "APPEARANCE",
        "key": "textSize",
        "choices": [
            "COMPACT",
            "STANDARD",
            "LARGE"
        ]
    },
    {
        "name": "FONT FAMILY",
        "key": "fontStyle",
        "choices": [
            "SYSTEM / CONSOLAS",
            "JETBRAINS MONO",
            "IBM PLEX MONO",
            "RAJDHANI",
            "OXANIUM"
        ]
    },
    {
        "name": "HIGHLIGHT ACCENT TINT",
        "key": "glintTint",
        "min": 0,
        "max": 100,
        "step": 5,
        "unit": "%"
    },
    {
        "name": "BACKGROUND BRIGHTNESS",
        "key": "brightness",
        "min": 0,
        "max": 100,
        "step": 5,
        "unit": "%"
    },
    {
        "name": "SELECTION ANIMATION",
        "key": "animationLevel",
        "choices": [
            "OFF",
            "SUBTLE",
            "MEDIUM",
            "INTENSE"
        ]
    },
    {
        "name": "SYNOPSIS",
        "key": "synopsis",
        "toggle": true,
        "on": "SHOW",
        "off": "HIDE"
    },
    {
        "name": "TYPEWRITER FOCUS",
        "key": "typewriter",
        "toggle": true
    },
{
    "name": "REDUCED MOTION",
    "section": "ACCESSIBILITY",
    "key": "reducedMotion",
    "toggle": true
},
{
    "name": "REDUCED FLASHES",
    "key": "reducedFlashes",
    "toggle": true
},
{
    "name": "HIGH CONTRAST MENUS",
    "key": "highContrast",
    "toggle": true
},
{
    "name": "STATIC PLAY CURSOR",
    "key": "staticCursor",
    "toggle": true
},
{
        "name": "BACKGROUND TRANSITION",
        "section": "BACKGROUND",
        "key": "transitionMode",
        "choices": [
            "TRIANGLES",
            "FADE",
            "INSTANT",
            "FROSTED PLEXUS",
            "ANGLED WIPE",
            "SIGNAL DECODE",
            "OBSIDIAN FRACTURE",
            "FILAMENT WEAVE"
        ]
    },
    {
        "name": "SOUND EFFECTS",
        "section": "AUDIO",
        "key": "sounds",
        "toggle": true
    },
    {
        "name": "SOUND PACK",
        "key": "soundPack",
        "choices": [
            "SOFT TICK",
            "SYNTH",
            "PULSE",
            "GLASS"
        ],
        "sound": true
    },
    {
        "name": "SOUND VOLUME",
        "key": "soundVolume",
        "min": 0,
        "max": 100,
        "step": 2,
        "unit": "%",
        "sound": true
    },
    {
        "name": "TRANSITION SOUND",
        "key": "transitionSound",
        "choices": [
            "OFF",
            "SOFT SWISH",
            "AIR WHOOSH",
            "SIGNAL SWEEP"
        ],
        "sound": true
    },
    {
        "name": "TRANSITION SOUND VOLUME",
        "key": "transitionVolume",
        "min": 0,
        "max": 100,
        "step": 5,
        "unit": "%",
        "sound": true,
        "transitionAudio": true
    },
    {
        "name": "ADVANCED SETTINGS",
        "section": "CONFIGURATION",
        "action": "developer"
    },
    {
        "name": "RETRY HELPER CONNECTION",
        "action": "retry"
    },
    {
        "name": "SAVE CONFIGURATION",
        "action": "save"
    },
    {
        "name": "RESET APPEARANCE",
        "action": "reset"
    },
    {
        "name": "BACK",
        "action": "back"
    }
]
    readonly property var developerRows: [
    {
        "name": "REPLAY BACKGROUND TRANSITION",
        "action": "preview",
        "section": "BACKGROUND"
    },
    {
        "name": "PARALLAX DEPTH",
        "key": "parallaxDepth",
        "min": 0,
        "max": 50,
        "step": 2,
        "unit": "px"
    },
    {
        "name": "TRIANGLE SIZE / DENSITY",
        "key": "triangleSize",
        "min": 18,
        "max": 180,
        "step": 2,
        "unit": "px",
        "section": "SHARED FACET CONTROLS",
        "modes": [
            0,
            3
        ]
    },
    {
        "name": "FACET FACET SHADING",
        "key": "prismStrength",
        "min": 0,
        "max": 100,
        "step": 5,
        "unit": "%",
        "modes": [
            0,
            3
        ]
    },
    {
        "name": "FACET EDGE STROKES",
        "key": "plexusEdges",
        "min": 0,
        "max": 100,
        "step": 5,
        "unit": "%",
        "modes": [
            0,
            3
        ]
    },
    {
        "name": "FACET REVEAL FADE LENGTH",
        "key": "plexusFade",
        "min": 15,
        "max": 70,
        "step": 5,
        "unit": "%",
        "modes": [
            0,
            3
        ]
    },
    {
        "name": "FACET MESH MOTION",
        "key": "plexusMotion",
        "min": 0,
        "max": 100,
        "step": 5,
        "unit": "%",
        "modes": [
            0,
            3
        ]
    },
    {
        "name": "PRISM COLOUR SPLIT",
        "key": "prismSplit",
        "min": 0,
        "max": 100,
        "step": 5,
        "unit": "%",
        "modes": [
            0,
            3
        ]
    },
    {
        "name": "PRISM SPLIT DISTANCE",
        "key": "prismDistance",
        "min": 0,
        "max": 48,
        "step": 1,
        "unit": "px",
        "modes": [
            0,
            3
        ]
    },
    {
        "name": "PRISM SPLIT ANGLE",
        "key": "prismAngle",
        "min": 0,
        "max": 360,
        "step": 5,
        "unit": "deg",
        "modes": [
            0,
            3
        ]
    },
    {
        "name": "BACKGROUND TRANSITION SPEED",
        "key": "transitionMs",
        "min": 100,
        "max": 2000,
        "step": 50,
        "unit": "ms",
        "modes": [
            0,
            1
        ],
        "section": "TRIANGLES / FADE TIMING"
    },
    {
        "name": "FACET BLUR",
        "section": "FROSTED PLEXUS",
        "key": "frostBlur",
        "min": 0,
        "max": 30,
        "step": 1,
        "unit": "px",
        "modes": [
            3
        ]
    },
    {
        "name": "BLURRED FACET REVEAL",
        "key": "frostRevealMs",
        "min": 200,
        "max": 4000,
        "step": 100,
        "unit": "ms",
        "modes": [
            3
        ]
    },
    {
        "name": "BLURRED HOLD",
        "key": "frostHoldMs",
        "min": 0,
        "max": 1500,
        "step": 50,
        "unit": "ms",
        "modes": [
            3
        ]
    },
    {
        "name": "RANDOM FACET SHARPEN",
        "key": "frostSharpMs",
        "min": 200,
        "max": 4000,
        "step": 100,
        "unit": "ms",
        "modes": [
            3
        ]
    },
    {
        "name": "WIPE TRANSITION SPEED",
        "key": "wipeMs",
        "min": 100,
        "max": 4000,
        "step": 50,
        "unit": "ms",
        "section": "ANGLED WIPE",
        "modes": [
            4
        ]
    },
    {
        "name": "WIPE ANGLE",
        "key": "wipeAngle",
        "min": 0,
        "max": 360,
        "step": 5,
        "unit": "deg",
        "modes": [
            4
        ]
    },
    {
        "name": "WIPE EDGE SOFTNESS",
        "key": "wipeSoftness",
        "min": 0,
        "max": 80,
        "step": 2,
        "unit": "px",
        "modes": [
            4
        ]
    },
    {
        "name": "REVERSE WIPE",
        "key": "wipeReverse",
        "toggle": true,
        "modes": [
            4
        ]
    },
    {
        "name": "WIPE FOLLOWS NAVIGATION",
        "key": "wipeFollow",
        "toggle": true,
        "modes": [
            4
        ]
    },
    {
        "name": "DECODE SPEED",
        "key": "decodeMs",
        "min": 200,
        "max": 4000,
        "step": 50,
        "unit": "ms",
        "modes": [
            5
        ],
        "section": "SIGNAL DECODE"
    },
    {
        "name": "DECODE NEON HALO RADIUS",
        "key": "decodeHaloRadius",
        "min": 0,
        "max": 64,
        "step": 4,
        "unit": "px",
        "modes": [
            5
        ]
    },
    {
        "name": "DECODE NEON BLOOM INTENSITY",
        "key": "decodeBloomIntensity",
        "min": 0,
        "max": 200,
        "step": 5,
        "unit": "%",
        "modes": [
            5
        ]
    },
    {
        "name": "CHARACTER CELL SIZE",
        "key": "decodeCell",
        "min": 6,
        "max": 12,
        "step": 1,
        "unit": "px",
        "modes": [
            5
        ]
    },
    {
        "name": "DECODE SCATTER",
        "key": "decodeScatter",
        "min": 0,
        "max": 100,
        "step": 5,
        "unit": "%",
        "modes": [
            5
        ]
    },
    {
        "name": "CHARACTER STAGE LENGTH",
        "key": "decodeHold",
        "min": 20,
        "max": 80,
        "step": 5,
        "unit": "%",
        "modes": [
            5
        ]
    },
    {
        "name": "CHARACTER GLOW",
        "key": "decodeGlow",
        "min": 0,
        "max": 100,
        "step": 5,
        "unit": "%",
        "modes": [
            5
        ]
    },
    {
        "name": "DECODE WIPE ANGLE",
        "key": "decodeAngle",
        "min": 0,
        "max": 360,
        "step": 5,
        "unit": "deg",
        "modes": [
            5
        ]
    },
    {
        "name": "DECODE WIPE SOFTNESS",
        "key": "decodeSoftness",
        "min": 0,
        "max": 40,
        "step": 1,
        "unit": "px",
        "modes": [
            5
        ]
    },
    {
        "name": "CHARACTER CHANGE INTERVAL",
        "key": "decodeCharacterMs",
        "min": 30,
        "max": 500,
        "step": 10,
        "unit": "ms",
        "modes": [
            5
        ]
    },
    {
        "name": "DECODE WIPE REVERSE",
        "key": "decodeReverse",
        "modes": [
            5
        ],
        "toggle": true
    },
    {
        "name": "DECODE FOLLOWS NAVIGATION",
        "key": "decodeFollow",
        "modes": [
            5
        ],
        "toggle": true
    },
    {
        "name": "ANIMATE CHARACTERS",
        "key": "decodeAnimate",
        "modes": [
            5
        ],
        "toggle": true
    },
    {
        "name": "FRACTURE SPEED",
        "key": "fractureMs",
        "min": 200,
        "max": 4000,
        "step": 50,
        "unit": "ms",
        "modes": [
            6
        ],
        "section": "OBSIDIAN FRACTURE"
    },
    {
        "name": "VORONOI PANE SIZE",
        "key": "fractureSize",
        "min": 70,
        "max": 400,
        "step": 10,
        "unit": "px",
        "modes": [
            6
        ]
    },
    {
        "name": "FRACTURE SHAPE RANDOMNESS",
        "key": "fractureRandomness",
        "min": 0,
        "max": 100,
        "step": 5,
        "unit": "%",
        "modes": [
            6
        ]
    },
    {
        "name": "GLASS PIECE LIMIT",
        "key": "fractureLimit",
        "min": 32,
        "max": 128,
        "step": 8,
        "unit": "",
        "modes": [
            6
        ]
    },
    {
        "name": "CENTRE BREAKUP RADIUS",
        "key": "fractureImpactRadius",
        "min": 15,
        "max": 80,
        "step": 5,
        "unit": "%",
        "modes": [
            6
        ]
    },
    {
        "name": "FINE CENTRE FRAGMENTS",
        "key": "fractureCoreSplit",
        "min": 0,
        "max": 100,
        "step": 5,
        "unit": "%",
        "modes": [
            6
        ]
    },
    {
        "name": "OPTICAL FLARE INTENSITY",
        "key": "fractureFlare",
        "min": 0,
        "max": 300,
        "step": 5,
        "unit": "%",
        "modes": [
            6
        ]
    },
    {
    "name": "OPTICAL FLARE WIDTH",
    "key": "fractureFlareSpan",
    "min": 20,
    "max": 180,
    "step": 5,
    "unit": "%",
    "modes": [
        6
    ]
},
    {
    "name": "OPTICAL FLARE HALO RADIUS",
    "key": "fractureFlareHalo",
    "min": 0,
    "max": 128,
    "step": 4,
    "unit": "px",
    "modes": [
        6
    ]
},
    {
    "name": "OPTICAL FLARE BLOOM",
    "key": "fractureFlareBloom",
    "min": 0,
    "max": 400,
    "step": 10,
    "unit": "%",
    "modes": [
        6
    ]
},
    {
        "name": "MAXIMUM OPTICAL FLARES",
        "key": "fractureFlareCount",
        "min": 0,
        "max": 16,
        "step": 1,
        "unit": "",
        "modes": [
            6
        ]
    },
    {
        "name": "SECONDARY BREAKUP",
        "key": "fractureSplit",
        "min": 0,
        "max": 100,
        "step": 5,
        "unit": "%",
        "modes": [
            6
        ]
    },
    {
        "name": "CHILD PANES PER BREAK",
        "key": "fractureChildren",
        "min": 2,
        "max": 5,
        "step": 1,
        "unit": "",
        "modes": [
            6
        ]
    },
    {
        "name": "INDEPENDENT SHARD SPREAD",
        "key": "fractureSeparation",
        "min": 0,
        "max": 100,
        "step": 5,
        "unit": "%",
        "modes": [
            6
        ]
    },
    {
        "name": "CAMERA GLINT INTENSITY",
        "key": "fractureSpecular",
        "min": 0,
        "max": 200,
        "step": 5,
        "unit": "%",
        "modes": [
            6
        ]
    },
    {
        "name": "CAMERA GLINT WIDTH",
        "key": "fractureGlintWidth",
        "min": 5,
        "max": 60,
        "step": 1,
        "unit": "%",
        "modes": [
            6
        ]
    },
    {
        "name": "CAMERA GLINT DURATION",
        "key": "fractureGlintDuration",
        "min": 16,
        "max": 300,
        "step": 5,
        "unit": "ms",
        "modes": [
            6
        ]
    },
    {
        "name": "SHARD DEPTH / TRAVEL",
        "key": "fractureTravel",
        "min": 0,
        "max": 1200,
        "step": 20,
        "unit": "px",
        "modes": [
            6
        ]
    },
    {
        "name": "SHARD ROTATION",
        "key": "fractureSpin",
        "min": 0,
        "max": 180,
        "step": 5,
        "unit": "deg",
        "modes": [
            6
        ]
    },
    {
        "name": "REFRACTION DEPTH",
        "key": "fractureDepth",
        "min": 0,
        "max": 60,
        "step": 1,
        "unit": "px",
        "modes": [
            6
        ]
    },
    {
        "name": "PANE TILT",
        "key": "fractureTilt",
        "min": 0,
        "max": 18,
        "step": 1,
        "unit": "deg",
        "modes": [
            6
        ]
    },
    {
        "name": "FRACTURE SCATTER",
        "key": "fractureScatter",
        "min": 0,
        "max": 100,
        "step": 5,
        "unit": "%",
        "modes": [
            6
        ]
    },
    {
        "name": "GLASS EDGE GLINTS",
        "key": "fractureGlints",
        "min": 0,
        "max": 100,
        "step": 5,
        "unit": "%",
        "modes": [
            6
        ]
    },
    {
        "name": "GLASS FACE OPACITY",
        "key": "fractureOpacity",
        "min": 10,
        "max": 100,
        "step": 5,
        "unit": "%",
        "modes": [
            6
        ]
    },
    {
        "name": "GLASS FACE REFLECTIONS",
        "key": "fractureReflection",
        "min": 0,
        "max": 150,
        "step": 5,
        "unit": "%",
        "modes": [
            6
        ]
    },
    {
        "name": "GLASS THICKNESS",
        "key": "fractureThickness",
        "min": 0,
        "max": 32,
        "step": 1,
        "unit": "px",
        "modes": [
            6
        ]
    },
    {
        "name": "GLASS EDGE WIDTH",
        "key": "fractureBevel",
        "min": 0,
        "max": 12,
        "step": 1,
        "unit": "px",
        "modes": [
            6
        ]
    },
    {
        "name": "WEAVE SPEED",
        "key": "weaveMs",
        "min": 200,
        "max": 4000,
        "step": 50,
        "unit": "ms",
        "modes": [
            7
        ],
        "section": "FILAMENT WEAVE"
    },
    {
        "name": "WEAVE NEON HALO RADIUS",
        "key": "weaveHaloRadius",
        "min": 0,
        "max": 128,
        "step": 4,
        "unit": "px",
        "modes": [
            7
        ]
    },
    {
        "name": "WEAVE NEON BLOOM INTENSITY",
        "key": "weaveBloomIntensity",
        "min": 0,
        "max": 400,
        "step": 5,
        "unit": "%",
        "modes": [
            7
        ]
    },
    {
        "name": "RIBBON WIDTH",
        "key": "weaveWidth",
        "min": 8,
        "max": 640,
        "step": 8,
        "unit": "px",
        "modes": [
            7
        ]
    },
    {
        "name": "RIBBON BEND",
        "key": "weaveBend",
        "min": 0,
        "max": 200,
        "step": 1,
        "unit": "px",
        "modes": [
            7
        ]
    },
    {
        "name": "WEAVE ANGLE",
        "key": "weaveAngle",
        "min": 0,
        "max": 180,
        "step": 1,
        "unit": "deg",
        "modes": [
            7
        ]
    },
    {
        "name": "WEAVE STAGGER",
        "key": "weaveStagger",
        "min": 0,
        "max": 200,
        "step": 5,
        "unit": "%",
        "modes": [
            7
        ]
    },
    {
        "name": "FILAMENT GLOW",
        "key": "weaveGlow",
        "min": 0,
        "max": 200,
        "step": 5,
        "unit": "%",
        "modes": [
            7
        ]
    },
    {
        "name": "IMAGE CONTOUR TRACING",
        "key": "weaveContours",
        "min": 0,
        "max": 200,
        "step": 5,
        "unit": "%",
        "modes": [
            7
        ]
    },
    {
        "name": "PARTICLE PLACEMENT",
        "section": "PARTICLES",
        "key": "particlePlacement",
        "choices": [
            "BOTTOM THIRD",
            "FULL SCREEN",
            "OUTER EDGES"
        ]
    },
    {
        "name": "EDGE DENSITY WEIGHTING",
        "key": "particleDensityBias",
        "toggle": true,
        "biasToggle": true
    },
    {
        "name": "EDGE DENSITY BIAS",
        "key": "particleEdgeBias",
        "min": 0,
        "max": 100,
        "step": 5,
        "unit": "%",
        "fullOnly": true,
        "density": true
    },
    {
        "name": "CENTER OPACITY MASK",
        "key": "particleCenterFade",
        "min": 0,
        "max": 100,
        "step": 5,
        "unit": "%"
    },
    {
        "name": "TOP DENSITY",
        "key": "particleTop",
        "min": 0,
        "max": 200,
        "step": 10,
        "unit": "%",
        "fullOnly": true,
        "density": true
    },
    {
        "name": "BOTTOM DENSITY",
        "key": "particleBottom",
        "min": 0,
        "max": 200,
        "step": 10,
        "unit": "%",
        "fullOnly": true,
        "density": true
    },
    {
        "name": "LEFT DENSITY",
        "key": "particleLeft",
        "min": 0,
        "max": 200,
        "step": 10,
        "unit": "%",
        "fullOnly": true,
        "density": true
    },
    {
        "name": "RIGHT DENSITY",
        "key": "particleRight",
        "min": 0,
        "max": 200,
        "step": 10,
        "unit": "%",
        "fullOnly": true,
        "density": true
    },
    {
        "name": "PARTICLE LIFETIME",
        "key": "particleLifetime",
        "min": 5,
        "max": 180,
        "step": 5,
        "unit": "sec"
    },
    {
        "name": "PIXEL COUNT",
        "key": "particleCount",
        "min": 0,
        "max": 180,
        "step": 6
    },
    {
        "name": "PIXEL SIZE",
        "key": "particleSize",
        "min": 1,
        "max": 8,
        "step": 1,
        "unit": "px"
    },
    {
        "name": "PIXEL SIZE VARIATION",
        "key": "particleVariation",
        "min": 0,
        "max": 100,
        "step": 5,
        "unit": "%"
    },
    {
        "name": "PIXEL DRIFT SPEED",
        "key": "particleSpeed",
        "min": 0,
        "max": 100,
        "step": 5,
        "unit": "%"
    },
    {
        "name": "PIXEL OPACITY",
        "key": "particleOpacity",
        "min": 0,
        "max": 100,
        "step": 2,
        "unit": "%"
    },
    {
        "name": "NAVIGATION WIND",
        "key": "particleWind",
        "min": 0,
        "max": 100,
        "step": 5,
        "unit": "%"
    },
    {
        "name": "REFLECTIVE GLINTS",
        "key": "particleGlint",
        "min": 0,
        "max": 100,
        "step": 5,
        "unit": "%"
    },
    {
        "name": "EXTENDED WIDTH RANGE",
        "section": "CARDS",
        "key": "overdrive",
        "toggle": true
    },
    {
        "name": "THUMBNAIL WIDTH",
        "key": "cardWidth",
        "min": 220,
        "max": 640,
        "step": 10,
        "unit": "px"
    },
    {
        "name": "THUMBNAIL ASPECT RATIO",
        "key": "cardAspect",
        "min": 160,
        "max": 320,
        "step": 10,
        "unit": "/100"
    },
    {
        "name": "SELECTED CARD SCALE",
        "key": "cardScale",
        "min": 100,
        "max": 118,
        "step": 1,
        "unit": "%"
    },
    {
        "name": "CARD PIVOT ANGLE",
        "key": "cardTilt",
        "min": 0,
        "max": 18,
        "step": 1,
        "unit": "deg"
    },
    {
        "name": "CARD / PARALLAX MOTION SPEED",
        "key": "motionMs",
        "min": 80,
        "max": 700,
        "step": 20,
        "unit": "ms"
    },
    {
        "name": "PLAY TYPEWRITER SPEED",
        "section": "TYPEWRITER",
        "key": "typewriterMs",
        "min": 10,
        "max": 120,
        "step": 2,
        "unit": "ms",
        "typing": true
    },
    {
        "name": "SYNOPSIS TYPEWRITER SPEED",
        "key": "synopsisMs",
        "min": 1,
        "max": 80,
        "step": 1,
        "unit": "ms",
        "typing": true
    },
    {
        "name": "DETAILS TYPEWRITER SPEED",
        "key": "metadataMs",
        "min": 5,
        "max": 100,
        "step": 1,
        "unit": "ms",
        "typing": true
    },
    {
        "name": "CURSOR BLINK SPEED",
        "key": "blinkMs",
        "min": 200,
        "max": 1400,
        "step": 50,
        "unit": "ms",
        "typing": true
    },
    {
        "name": "THUMBNAIL TRACK DARKNESS",
        "section": "APPEARANCE",
        "key": "trackOpacity",
        "min": 20,
        "max": 95,
        "step": 5,
        "unit": "%"
    },
    {
        "name": "CONTROLLER ICON TINT",
        "key": "iconTint",
        "min": 0,
        "max": 100,
        "step": 5,
        "unit": "%"
    },
    {
        "name": "SAVE CONFIGURATION",
        "section": "CONFIGURATION",
        "action": "save"
    },
    {
        "name": "RELOAD CONFIGURATION",
        "action": "reload"
    },
    {
        "name": "BACK TO APPEARANCE",
        "action": "appearance"
    }
]
    readonly property var rows: developer ? developerRows : appearanceRows
    readonly property int rowHeight: Math.round(46*owner.textScale)
    function limit(row) { if(row.key==="frostGlintMs") return Math.min(700,Math.round(owner.preferences.frostSharpMs*.4));return row.key==="cardWidth" && !owner.preferences.overdrive ? 360:row.max; }
    function tooltip() {
        var help={"helperAutoStart":"Windows only: start the optional Python artwork helper when unavailable. Configure and test it first. Off still connects to an already running helper; browsing and launching games do not require it.","startupSplash":"Show Relay by Operator once when the theme loads. Turn off to go directly to the library. Changes apply on the next theme load.","splashWait":"Keep the completed splash on screen until a key, controller button or mouse click is released. Off continues automatically. Arrow/stick movement never dismisses it.","reducedMotion":"Use a short crossfade, stationary cards and background, no particles or typewriter motion. Your detailed effect settings are retained for when this is off.","reducedFlashes":"Replace fracture and weave with a fade, remove decode bloom and character cycling, and disable particle and Play flashes. Does not alter the content of trailers.","highContrast":"Brighter menu text, opaque panels and white menu focus indicators, independent of your chosen accent colour. Decorative effects keep their colour.","staticCursor":"Keep the Play underscore steady instead of blinking.","trailerVolume":"Independent video volume. Trailers start only when you choose Watch trailer; this is separate from interface sounds.","fractureFlareSpan":"Typical flare width as a percentage of the screen. Central glints are larger; seeded variation makes each flash different.","fractureFlareHalo":"Radius of one shared soft accent halo around optical flares. Zero removes blur. This uses a quarter-resolution light layer.","fractureFlareBloom":"Brightness of the soft optical-flare bloom. The sharp white core stays separate. Zero disables bloom.","fractureLimit":"Hard cap on all glass pieces, including fine centre fragments. Start at 96 or 128 and check FPS.","fractureImpactRadius":"Central region eligible for smaller panes. Outside this region the larger original panes remain intact.","fractureCoreSplit":"Chance of an additional three-way subdivision for the innermost child panes, within the piece budget. All cuts exist before animation starts.","fractureFlare":"Strength of the optical flare sprite. Its halo uses the accent colour and its centre stays nearly white. Zero disables optical flares.","fractureFlareSize":"Screen width of each camera-facing flare in pixels. Large values increase overlapping light and fill cost.","fractureFlareCount":"Maximum shared-texture flare candidates. Angle and per-piece timing keep only some visible at once.","fractureSplit":"Percentage of eligible central panes subdivided before movement begins. Zero keeps the first Voronoi pattern. The piece cap can limit the requested percentage.","fractureChildren":"Smaller Voronoi polygons per selected parent pane, from 2 to 5. Shared meshes keep draw count fixed.","fractureSplitAt":"Delay before children separate, as a percentage of parent animation.","fractureSeparation":"Random per-piece spread from the centre. Every piece moves independently from the beginning.","fractureSpecular":"Brightness of brief camera-facing reflection peaks. White cores and small accent shoulders stay inside each pane.","fractureGlintWidth":"Width of the narrow reflection streak and local glint core. Higher values broaden the flash.","fractureGlintDuration":"Duration of the peak reflection in milliseconds. About 40-100ms gives a quick readable glint; very short flashes can fall between frames.","decodeHaloRadius":"Soft accent-coloured halo radius for decode only. Zero disables blur.","decodeBloomIntensity":"Bloom brightness for decode only. Zero disables bloom; other transitions retain their own settings.","weaveHaloRadius":"Soft accent-coloured halo radius for weave only. Zero disables blur.","weaveBloomIntensity":"Bloom brightness for weave only. Zero disables bloom; other transitions retain their own settings.","fractureRandomness":"Randomize Voronoi seed positions: 0% regular cells, 100% strongly irregular polygon panes. Independent of timing scatter.","fractureOpacity":"Opacity of each glass face while shards are moving. Lower values let the next image show through; the initial image stays intact.","fractureReflection":"Strength of broad face reflections and grazing-angle highlights, independent of thin edge glints.","fractureThickness":"Extruded depth of each polygon pane in pixels. Zero removes the side walls. More thickness makes tumbling edges easier to see. All walls share one rendering mesh.","fractureBevel":"Approximate width of the bright bevel around each face. Wider edges are more visible at the centre as well as screen boundaries.","decodeAngle":"Direction of the character reveal in degrees: 0 horizontal, 90 vertical; intermediate angles give diagonal wipes.","decodeSoftness":"Extra softness of the arrival boundary in pixels. Character stage length still controls the decode-to-image fade.","decodeReverse":"Reverse the selected decode wipe direction.","decodeFollow":"Reverse the decode wipe direction when moving left through games.","decodeAnimate":"Cycle each cell through nearby ASCII shapes while it decodes, retaining the incoming image brightness. OFF keeps the characters static.","decodeCharacterMs":"Milliseconds between character changes. Higher values animate more slowly.","frostSharpMs":"Time for blurred facets to sharpen in random order, without a highlighting sweep.","glowRadius":"Radius of the soft accent-coloured neon halo. The sharp source stays crisp. Larger values merge nearby halos.","glowIntensity":"Brightness of the separate blurred light layer. 0 disables bloom; 100 is normal, 200 is stronger.","fractureTravel":"Maximum movement through perspective depth, with outward travel. Larger values bring shards toward the camera and send others away.","fractureSpin":"Maximum independent shard rotation about horizontal and vertical axes.","decodeMs": "Time for the background to reconstruct through character cells.", "decodeCell": "Pixel size of each ASCII cell. Smaller cells show more image detail.", "decodeScatter": "Randomize cell arrival while retaining navigation direction.", "decodeHold": "Fraction of decoding time spent in the character stage before resolving to the image.", "decodeGlow": "Brightness of the accent-coloured characters and a soft halo.", "fractureMs": "Duration of the irregular glass-pane transition.", "fractureSize": "Approximate Voronoi polygon size. Larger values make fewer pieces. The glass piece limit bounds all panes, rendered in one face mesh and one wall mesh. Hold left/right to accelerate adjustment.", "fractureDepth": "Small image refraction within the moving shards. Depth movement is controlled by SHARD DEPTH / TRAVEL.", "fractureTilt": "Extra in-plane roll of the shards; SHARD ROTATION controls their out-of-plane tumble.", "fractureScatter": "Variation in pane reveal timing, along the navigation direction.", "fractureGlints": "Brightness of the glass face edges and side walls. Broad reflections have their own GLASS FACE REFLECTIONS control.", "weaveMs": "Time for interwoven ribbons to reveal the incoming background.", "weaveWidth": "Width of the horizontal and vertical image ribbons.", "weaveBend": "Temporary displacement around the weaving boundary.", "weaveAngle": "Rotation of the woven ribbon grid in degrees.", "weaveStagger": "Variation in the timing of neighbouring ribbon intersections.", "weaveGlow": "Intensity of the thin accent threads at ribbon boundaries.", "weaveContours": "Trace incoming image edges with subtle accent light during the transition.", "transitionSound": "Choose a short transition sound, independent of the navigation tick pack. OFF disables it.", "transitionVolume": "Transition sound volume, multiplied by the main interface volume.","wipeMs":"Time for the angled boundary to replace the background. Higher values are slower.","wipeAngle":"Wipe direction in degrees: 0 sweeps left to right, 90 top to bottom. Intermediate angles are diagonal.","wipeSoftness":"Width of the blend at the wipe boundary in pixels. Zero gives a crisp classic wipe.","wipeReverse":"Reverse the chosen wipe direction.","wipeFollow":"Reverse the wipe when moving left through games. Turn off for a fixed cinematic direction.","removeColour":"Remove the selected saved colour after confirmation. Built-in overrides revert to their original colour.","soundPack":"Four quiet tick packs with consistent pitches for direction, menus and Play focus.","glintTint":"How much facet and particle reflections use your accent: 0% white, 100% accent.","particleDensityBias":"Full-screen only. Enable edge bias and individual side population weights.","frostGlintMs":"Duration of each facet glint and sharpening event, capped at 40% of the sharpening stage.","particleCenterFade":"Fade pixel opacity toward the screen center. Edges retain the selected opacity.","accent": "Built-in and saved colours share this list. CUSTOM lets you adjust the colour channels.", "red": "Red channel of the custom accent, from 0 to 255.", "green": "Green channel of the custom accent, from 0 to 255.", "blue": "Blue channel of the custom accent, from 0 to 255.", "prompts": "AUTO follows the last identifiable input. Choose a controller family to override it.", "fontStyle": "Choose two monospace fonts, Rajdhani or Oxanium, or keep system Consolas.", "developer": "Open advanced background, particle and card controls. S is a shortcut.", "loadColour": "Left/right selects and loads a named accent. Enter loads the displayed colour.", "saveColour": "Save the current accent with a name. Duplicate names ask before replacing a saved colour or built-in preset.", "particlePlacement": "Place pixels in the bottom third, across the screen, or only around the outer edges.", "particleEdgeBias": "Full-screen edge weighting: higher values concentrate pixels near the edges. Requires density weighting.", "particleTop": "Relative population near the top edge. Zero excludes that side; total count stays bounded.", "particleBottom": "Relative population near the bottom edge. Higher values give this side more particles.", "particleLeft": "Relative population near the left edge, compared with the other enabled sides.", "particleRight": "Relative population near the right edge, compared with the other enabled sides.", "particleLifetime": "Average lifetime. New pixels fade in; they fade out during the last 10% of their life.", "particleCount": "Maximum live particle pool. Zero disables particles; they never block interaction.", "particleSize": "Base size of each square pixel, before random size variation.", "particleVariation": "Random size variation around the base pixel size.", "particleSpeed": "Ambient particle drift speed. Navigation wind moves the existing particles.", "particleOpacity": "Maximum pixel opacity; lifecycle fades temporarily reduce it. 100% is fully opaque.", "particleWind": "Direction-sensitive wind impulse when switching games, without resetting pixel positions.", "particleGlint": "Occasional reflective highlights and a restrained accent-coloured glow.", "frostBlur": "Blur amount inside each triangle mask during the frosted transition.", "frostRevealMs": "Time taken for the incoming blurred triangles to fade into view.", "frostHoldMs": "How long all facets hold their blurred state before sharpening starts.", "frostSharpMs":"Time for blurred facets to sharpen in random order, without a highlighting sweep.", "frostFlash": "Strength of the brief glass-like glint on each sharpening facet.", "frostScatter": "Random timing variation between facets, while preserving the overall center-out order.", "frostGlintWidth": "Width of each facet-local directional reflection; smaller values make a finer glint.", "frostGlintLength": "Each facet event duration as a percentage of the center-out sharpening stage.", "overdrive": "Enable thumbnail widths up to 640 px. Wider cards show fewer games at once.", "cardWidth": "Thumbnail width. Normal limit: 360 px; extended range: 640 px. Artwork uses its saved crop.", "cardAspect": "Thumbnail width divided by height. Higher ratios create a wider, shorter crop.", "cardScale": "Selected thumbnail enlargement. Selection animation strength also scales this effect.", "cardTilt": "Perspective pivot angle when switching cards. Zero disables the tilt.", "motionMs": "Card movement and background parallax duration. Higher milliseconds mean slower movement.", "prismStrength": "Simulated facet lighting and distance falloff during the background transition.", "plexusEdges": "Strength of the fine triangle edge strokes while the transition is running.", "plexusFade": "How much transition time each triangle spends fading between images.", "plexusMotion": "Gentle movement of mesh vertices during the transition. The final image settles flat.", "prismSplit": "Colour-channel separation during the transition. Pair with split distance for visibility.", "prismDistance": "Maximum pixel offset between separated colour channels during a facet transition.", "prismAngle": "Direction of the colour separation, in degrees, with slight facet-to-facet variation.", "preview": "Replay the selected transition so you can preview your background settings.", "parallaxDepth": "Horizontal background travel and extra crop margin while navigating games. Zero removes both. Shard depth uses Shard depth travel instead.", "transitionMode": "Choose a triangle reveal, crossfade, instant swap, frosted plexus, an angled wipe, signal decode, obsidian fracture or filament weave.", "triangleSize": "Size of the irregular triangle mesh. Smaller values create more triangles and GPU work.", "transitionMs": "Duration of the standard triangle or fade transition. Frosted mode has separate timings.", "brightness": "Brightness of the background artwork; menus and text keep their own contrast.", "animationLevel": "Overall card and parallax strength: off, subtle, medium or intense.", "synopsis": "Show or hide the selected game synopsis on the main screen.", "typewriter": "Enable typing for Play, developer details and synopsis. Navigation labels stay instant.", "sounds": "Enable the quiet navigation ticks and the distinct Play-focus sound.", "soundVolume": "Volume of interface sound effects. Lower values make navigation less intrusive.", "textSize": "Scale interface text while keeping the artwork as the focus.", "typewriterMs": "Delay per character on Play. Higher values type more slowly.", "synopsisMs": "Separate delay per character for the game synopsis.", "metadataMs": "Separate delay per character for the developer and source details.", "blinkMs": "Cursor blink interval. The blinking underscore appears only on Play.", "trackOpacity": "Darkness of the shared thumbnail track behind artwork and titles.", "iconTint": "How strongly controller button icons inherit your accent colour.", "retry": "Retry the local metadata helper connection. Current status: ", "save": "Write current settings to relay-settings.json through the helper.", "reload": "Reload the saved configuration from relay-settings.json.", "reset": "Reset appearance and effect values. Saved colours, game crops, text/font choices and accessibility settings are kept.", "back": "Close settings and return to your current game.", "appearance": "Return to the main appearance and controls menu."};
        var row=rows[selected];if(!row) return "Choose a setting to see its description.";var text=help[row.key || row.action] || row.name;
        return row.action==="retry" ? text+owner.helperConnection:text;
    }
    function scrollWheel(delta) { settingsScroll.contentY=Math.max(0,Math.min(Math.max(0,settingsScroll.contentHeight-settingsScroll.height),settingsScroll.contentY-delta*0.5)); }
    function normalizeSelection() { if(!owner || !rows.length) return;if(available(selected)) return;for(var i=0;i<rows.length;i++) if(available(i)) {selected=i;return;} }
    Connections {target:panel.owner;onPreferencesChanged:panel.normalizeSelection()}
    function visibleRow(i) {
        var row=rows[i],p=owner.preferences;if(!row) return false;
        return (!row.custom || p.accent>=5) && (!row.fullOnly || p.particlePlacement===1) && (!row.typing || p.typewriter);
    }
    function available(i) {
        var row=rows[i],p=owner.preferences;if(!row || !visibleRow(i) || row.modes && row.modes.indexOf(p.transitionMode)<0) return false;
        if(row.key==="splashWait" && !p.startupSplash) return false;
        if(row.action==="removeColour") return owner.colourIndex(owner.accentNames[p.accent],p.savedColours)>=0;
        return ((["fractureFlareSpan","fractureFlareHalo","fractureFlareBloom","fractureFlareCount"].indexOf(row.key)<0) || p.fractureFlare>0) && ((["fractureChildren","fractureCoreSplit","fractureImpactRadius"].indexOf(row.key)<0) || p.fractureSplit>0) && ((["fractureGlintWidth","fractureGlintDuration"].indexOf(row.key)<0) || p.fractureSpecular>0) && (row.key!=="decodeCharacterMs" || p.decodeAnimate) && (!row.sound || p.sounds) && (!row.transitionAudio || p.transitionSound>0) && (!row.density || p.particleDensityBias) && (!row.biasToggle || p.particlePlacement===1) && ((row.key!=="prismAngle" && row.key!=="prismDistance") || p.prismSplit>0);
    }
    function value(i) {
        var row=rows[i],p=owner.preferences;
        if(row.key==="accent") return owner.accentNames[p.accent];
        if(row.action==="loadColour") return p.savedColours.length ? p.savedColours[savedColourIndex%p.savedColours.length].name : "NONE";
        if(row.action) return ">";
        if(row.key==="cardAspect") return (p.cardAspect/100).toFixed(2)+" : 1";
        if(row.choices) return row.choices[p[row.key]];
        if(row.toggle) return p[row.key] ? (row.on || "ON") : (row.off || "OFF");
        return p[row.key]+(row.unit ? " "+row.unit : "");
    }
    function change(delta,multiplier) {
        var row=rows[selected];if(!available(selected)) return;
        if(row.action==="loadColour") { savedColourIndex=(savedColourIndex+delta+owner.preferences.savedColours.length)%owner.preferences.savedColours.length;owner.loadNamedColour(savedColourIndex);owner.feedback("settings");return; }
        if(row.action) return;
        var value=owner.preferences[row.key];
        if(row.key==="accent") value=(value+delta+owner.accentNames.length)%owner.accentNames.length;
        else if(row.choices) value=(value+delta+row.choices.length)%row.choices.length;
        else if(row.toggle) value=!value;
        else value=Math.max(row.min,Math.min(limit(row),value+delta*row.step*(multiplier || 1)));
        owner.setPreference(row.key,value); owner.feedback("settings");
    }
    function openDeveloper() { developer=true;selected=0;normalizeSelection();settingsScroll.contentY=0;panel.forceActiveFocus(); }
    function activate() {
        var row=rows[selected];if(!available(selected)) return; if(!row.action) { change(1); return; }
        owner.feedback("confirm");
        if(row.action==="developer") { openDeveloper(); }
        else if(row.action==="appearance") { developer=false; selected=appearanceRows.map(function(r){return r.action;}).indexOf("developer"); settingsScroll.contentY=0; ensureVisible(); }
        else if(row.action==="retry") { owner.helperConnection="Connecting..."; owner.ensureHelper(); }
        else if(row.action==="save") owner.saveConfiguration();
        else if(row.action==="reload") owner.loadConfiguration();
        else if(row.action==="preview") { owner.replayTransition(); previewDim=true; previewTimer.restart(); }
        else if(row.action==="reset") owner.resetAppearance();
        else if(row.action==="saveColour") owner.colourEditorOpen=true;
        else if(row.action==="removeColour") owner.requestRemoveColour();
        else if(row.action==="loadColour") owner.loadNamedColour(savedColourIndex%owner.preferences.savedColours.length);
        else owner.closeSettings();
    }
    function ensureVisible() {
        if(!rows.length || selected>=rows.length) return;
        var top=0;for(var i=0;i<selected;i++) if(visibleRow(i)) top+=rowHeight+(rows[i].section ? 64:0);
        top+=rows[selected].section ? 64:0;
        if(top<settingsScroll.contentY) settingsScroll.contentY=top;
        else if(top+rowHeight>settingsScroll.contentY+settingsScroll.height) settingsScroll.contentY=top+rowHeight-settingsScroll.height;
    }
    onSelectedChanged: {stopAdjustHold();ensureVisible();}
    function move(delta) { do { selected=(selected+delta+rows.length)%rows.length; } while(!available(selected)); ensureVisible(); owner.feedback("settings"); }
    function back() { if(developer) { developer=false; selected=appearanceRows.map(function(r){return r.action;}).indexOf("developer"); Qt.callLater(ensureVisible); owner.feedback("back"); } else owner.closeSettings(); }
    Timer { id: previewTimer; interval: panel.owner.backgroundTransitionDuration*2+700; onTriggered: panel.previewDim=false }
    Rectangle { anchors.fill: parent; color:panel.owner.menuPalette.backdrop; opacity: panel.previewDim ? 0 : 1;MouseArea {anchors.fill:parent;onClicked:{} onWheel:{panel.scrollWheel(wheel.angleDelta.y);wheel.accepted=true;}} }
    Rectangle {
        anchors.centerIn: parent; width:Math.min(parent.width*0.8,1180); height:Math.min(parent.height*0.86,900)
        opacity: panel.previewDim ? 0.12 : 1
        Behavior on opacity { NumberAnimation { duration:180 } }
        color:panel.owner.menuPalette.panel; border.width:1; border.color:panel.owner.menuPalette.focusColor
        Column {
            anchors.fill:parent; anchors.margins:30; spacing:18
            Item {width:parent.width;height:26*panel.owner.textScale
            Text { text:panel.developer ? "RELAY / ADVANCED" : "RELAY / SETTINGS"; color:panel.owner.menuPalette.focusColor; font.family:panel.owner.monoFont; font.pixelSize:20*panel.owner.textScale; font.letterSpacing:2 }
            Text {anchors.right:parent.right;anchors.verticalCenter:parent.verticalCenter;text:"OPERATOR / v0.13.0-beta1";color:panel.owner.menuPalette.muted;font.family:panel.owner.monoFont;font.pixelSize:12*panel.owner.textScale}
            }
            Text { width:parent.width; text:panel.tooltip();height:32*panel.owner.textScale;wrapMode:Text.Wrap; color:panel.owner.menuPalette.muted; font.family:panel.owner.monoFont; font.pixelSize:12*panel.owner.textScale }
            Rectangle { width:parent.width; height:1; color:panel.owner.menuPalette.focusColor; opacity:0.25 }
            Item {
                width:parent.width; height:Math.max(100,parent.height-214-(panel.owner.textScale-1)*72)
            Flickable {
                id:settingsScroll;objectName:"relaySettingsScroll"; anchors.fill:parent;anchors.rightMargin:20; contentHeight:settingsRows.height; clip:true
                Column {
                    id:settingsRows; width:parent.width
                    Repeater {
                        model:panel.rows
                        Item {
                            width:settingsRows.width; height:visible ? panel.rowHeight+(modelData.section ? 64:0) : 0; visible:panel.visibleRow(index)
                            Text { visible:!!modelData.section; y:24;text:modelData.section || "";color:panel.owner.menuPalette.focusColor;font.family:panel.owner.monoFont;font.pixelSize:12*panel.owner.textScale;font.letterSpacing:2 }
                            Rectangle { visible:!!modelData.section;y:48;width:parent.width;height:1;color:panel.owner.menuPalette.focusColor;opacity:0.2 }
                        Rectangle {
                            id:settingRow
                            opacity:panel.available(index) ? 1:0.35
                            y:modelData.section ? 64:0
                            width:settingsRows.width; height:panel.rowHeight
                            color:panel.selected===index ? panel.owner.menuPalette.selectedFill : "transparent"
                            border.width:panel.selected===index ? (panel.owner.preferences.highContrast ? 2:1) : 0; border.color:panel.owner.menuPalette.focusColor
                            property var rowData: modelData
                            Text { anchors.left:parent.left; anchors.leftMargin:14; anchors.verticalCenter:parent.verticalCenter; width:parent.width-350; elide:Text.ElideRight; text:(panel.selected===index ? "> " : "  ")+modelData.name; color:panel.selected===index ? panel.owner.menuPalette.focusColor : panel.owner.menuPalette.text; font.family:panel.owner.monoFont; font.pixelSize:14*panel.owner.textScale }
                            Text { anchors.right:parent.right; anchors.rightMargin:34; anchors.verticalCenter:parent.verticalCenter; text:panel.value(index); color:panel.owner.menuPalette.focusColor; font.family:panel.owner.monoFont; font.pixelSize:14*panel.owner.textScale }
                            MouseArea { anchors.fill:parent; onClicked:{if(!panel.available(index)) return;panel.owner.observePointer();panel.selected=index;panel.activate();if(!panel.owner.colourEditorOpen && !panel.owner.colourConfirmation) panel.forceActiveFocus();} onWheel:{panel.scrollWheel(wheel.angleDelta.y);wheel.accepted=true;} }
                            Rectangle {
                                visible:!modelData.action && !modelData.toggle && !modelData.choices
                                anchors.right:parent.right;anchors.rightMargin:155;anchors.verticalCenter:parent.verticalCenter;width:110;height:3;color:panel.owner.menuPalette.line
                                Rectangle { height:parent.height; width:parent.width*(settingRow.rowData.min!==undefined ? Math.min(1,(panel.owner.preferences[settingRow.rowData.key]-settingRow.rowData.min)/(panel.limit(settingRow.rowData)-settingRow.rowData.min)) : 0); color:panel.owner.menuPalette.focusColor }
                                MouseArea {
                                    anchors.fill:parent;anchors.topMargin:-15;anchors.bottomMargin:-15
                                    function adjust(x) {if(!panel.available(index)) return;var row=settingRow.rowData;panel.selected=index;panel.owner.setPreference(row.key,Math.round(row.min+Math.max(0,Math.min(1,x/width))*(panel.limit(row)-row.min)));panel.owner.observePointer();panel.forceActiveFocus(); }
                                    onWheel:{panel.scrollWheel(wheel.angleDelta.y);wheel.accepted=true;}
                                    onPressed:adjust(mouse.x); onPositionChanged:if(pressed) adjust(mouse.x)
                                }
                            }
                            Text { visible:!modelData.action; anchors.right:parent.right;anchors.rightMargin:280;anchors.verticalCenter:parent.verticalCenter;text:"<";color:panel.owner.menuPalette.focusColor;font.family:panel.owner.monoFont;font.pixelSize:16; MouseArea { anchors.fill:parent;anchors.margins:-10;onClicked:{if(!panel.available(index)) return;panel.owner.observePointer();panel.selected=index;panel.change(-1);panel.forceActiveFocus();} } }
                            Text { visible:!modelData.action; anchors.right:parent.right;anchors.rightMargin:12;anchors.verticalCenter:parent.verticalCenter;text:">";color:panel.owner.menuPalette.focusColor;font.family:panel.owner.monoFont;font.pixelSize:16; MouseArea { anchors.fill:parent;anchors.margins:-10;onClicked:{if(!panel.available(index)) return;panel.owner.observePointer();panel.selected=index;panel.change(1);panel.forceActiveFocus();} } }
                        }
                        }
                    }
                }
            }
                Rectangle {
                    anchors.right:parent.right;width:6;height:parent.height
                    visible:settingsScroll.contentHeight>settingsScroll.height;color:panel.owner.menuPalette.line
                    Rectangle { width:parent.width;height:Math.max(28,parent.height*settingsScroll.height/settingsScroll.contentHeight);y:Math.max(0,Math.min(parent.height-height,settingsScroll.contentY/(settingsScroll.contentHeight-settingsScroll.height)*(parent.height-height)));color:panel.owner.menuPalette.focusColor;opacity:0.75 }
                    MouseArea { anchors.fill:parent;onPressed:{panel.owner.observePointer();scrollTo(mouse.y);}onPositionChanged:if(pressed) scrollTo(mouse.y);function scrollTo(y){settingsScroll.contentY=Math.max(0,Math.min(settingsScroll.contentHeight-settingsScroll.height,y/height*(settingsScroll.contentHeight-settingsScroll.height)));} }
                }
            }
            Rectangle {width:parent.width;height:1;color:panel.owner.menuPalette.focusColor;opacity:0.25}
            Text {width:parent.width;text:panel.owner.configStatus;elide:Text.ElideRight;color:panel.owner.menuPalette.muted;font.family:panel.owner.monoFont;font.pixelSize:12*panel.owner.textScale}
            Row {width:parent.width;height:26
                Item {width:parent.width/3;height:26;ControlPrompt {anchors.centerIn:parent;owner:panel.owner;keyText:"ARROWS";buttons:panel.owner.promptButtons("navigate");label:"CHOOSE / ADJUST"}}
                Item {width:parent.width/3;height:26;ControlPrompt {anchors.centerIn:parent;owner:panel.owner;keyText:"ENTER";buttons:panel.owner.promptButtons("accept");label:"SELECT"}}
                Item {width:parent.width/3;height:26;ControlPrompt {anchors.centerIn:parent;owner:panel.owner;keyText:"ESC";buttons:panel.owner.promptButtons("cancel");label:"BACK"}}
            }
        }
    }
    Keys.onReleased: {if((event.key===Qt.Key_Left || event.key===Qt.Key_Right) && !event.isAutoRepeat){event.accepted=true;panel.stopAdjustHold();}}
    Keys.onPressed: {
        panel.owner.observeInput(event);
        if(event.key===Qt.Key_S){event.accepted=true;if(!event.isAutoRepeat && !panel.developer) { panel.openDeveloper();panel.owner.feedback("settings"); }}
        else if(event.key===Qt.Key_Escape || api.keys.isCancel(event)){event.accepted=true;if(!event.isAutoRepeat) panel.back();}
        else if(event.key===Qt.Key_Up || event.key===Qt.Key_Down || event.key===Qt.Key_Tab || event.key===Qt.Key_Backtab){event.accepted=true;panel.move(event.key===Qt.Key_Up || event.key===Qt.Key_Backtab || (event.modifiers & Qt.ShiftModifier) ? -1:1);}
        else if(event.key===Qt.Key_Left || event.key===Qt.Key_Right){event.accepted=true;if(!event.isAutoRepeat) panel.beginAdjustHold(event.key===Qt.Key_Left ? -1:1);}
        else if(event.key===Qt.Key_Return || event.key===Qt.Key_Enter || api.keys.isAccept(event)){event.accepted=true;if(!event.isAutoRepeat) panel.activate();}
        else event.accepted=true;
    }
}

