import QtQuick 2.8

Row {
    id: prompt
    property var owner
    property string keyText: ""
    property var buttons: []
    property string label: ""
    property int iconSize: 28
    spacing: 9
    height: Math.max(iconSize, caption.height)
    function iconName(button) {
        var xbox = {a:"xbox_button_a",b:"xbox_button_b",x:"xbox_button_x",y:"xbox_button_y",lb:"xbox_lb",rb:"xbox_rb",lt:"xbox_lt",rt:"xbox_rt",ls:"xbox_ls",dpad:"xbox_dpad",rs:"xbox_rs",view:"xbox_button_view",menu:"xbox_button_menu",guide:"xbox_guide"};
        var ps = {a:"playstation_button_cross",b:"playstation_button_circle",x:"playstation_button_square",y:"playstation_button_triangle",lb:"playstation_trigger_l1",rb:"playstation_trigger_r1",lt:"playstation_trigger_l2",rt:"playstation_trigger_r2",ls:"playstation_stick_l_press",dpad:"playstation_dpad",rs:"playstation_stick_r_press",view:"playstation4_button_share",menu:"playstation4_button_options",guide:""};
        return (owner.controllerStyle === "playstation" ? ps : xbox)[button] || "";
    }
    Text {
        visible: prompt.owner.keyboardHints
        anchors.verticalCenter: parent.verticalCenter
        text: "[" + prompt.keyText + "]"
        color: prompt.owner.menuPalette.focusColor
        font.family: prompt.owner.monoFont; font.pixelSize: (prompt.iconSize < 28 ? 12 : 14) * prompt.owner.textScale
    }
    Row {
        visible: !prompt.owner.keyboardHints
        spacing: 3; anchors.verticalCenter: parent.verticalCenter
        Repeater {
            model: prompt.buttons
            Item {
                width: prompt.iconSize; height: prompt.iconSize
                Image { id: glyph; anchors.fill: parent; source: prompt.iconName(modelData) ? "../assets/input/" + prompt.iconName(modelData) + ".png" : ""; fillMode: Image.PreserveAspectFit; smooth: true
                    layer.enabled: GraphicsInfo.api===GraphicsInfo.OpenGL
                    layer.effect: ShaderEffect {
                        property variant source
                        property color tint: prompt.owner.accent
                        property real tintAmount: prompt.owner.preferences.iconTint/100
                        fragmentShader: "varying highp vec2 qt_TexCoord0; uniform sampler2D source; uniform lowp vec4 tint; uniform lowp float tintAmount; uniform lowp float qt_Opacity; void main(){ lowp vec4 s=texture2D(source,qt_TexCoord0); gl_FragColor=vec4(mix(s.rgb,tint.rgb*s.a,tintAmount),s.a)*qt_Opacity; }"
                    }
                }
                Text { anchors.centerIn: parent; visible: glyph.status !== Image.Ready; text: modelData.toUpperCase(); color: prompt.owner.menuPalette.focusColor; font.family: prompt.owner.monoFont; font.pixelSize: 11 }
            }
        }
    }
    Text {
        id: caption
        visible: prompt.label.length > 0
        anchors.verticalCenter: parent.verticalCenter
        text: prompt.label; color: prompt.owner.preferences.highContrast ? prompt.owner.menuPalette.text:"#8c9693"
        font.family: prompt.owner.monoFont; font.pixelSize: 13 * prompt.owner.textScale; font.letterSpacing: 0.6
    }
}
