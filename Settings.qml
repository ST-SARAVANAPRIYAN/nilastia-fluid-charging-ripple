import Nilastia.Plugins
import QtQuick

SettingsObject {
    property real waveSpeed: 1.0
    property real noiseStrength: 1.0
    property string rippleColor: "#8839ef"
    property string animationType: "out-expo"
    property bool autoColor: true
    property real ringWidth: 0.25
    property real waveStrength: 1.0

    SettingMeta on waveSpeed {
        label: "Wave Speed"
        description: "Speed of the expanding fluid animation"
        inputType: SettingMeta.Slider
        min: 0.1
        max: 5.0
        step: 0.1
    }

    SettingMeta on noiseStrength {
        label: "Sparkle Intensity"
        description: "Intensity of the sparkling fluid noise"
        inputType: SettingMeta.Slider
        min: 0.0
        max: 3.0
        step: 0.1
    }

    SettingMeta on rippleColor {
        label: "Ripple Color"
        description: "Color of the fluid charging ripple overlay"
        inputType: SettingMeta.TextField
    }

    SettingMeta on animationType {
        label: "Animation Type"
        description: "Transition curve for the expansion"
        inputType: SettingMeta.TextField
    }

    SettingMeta on autoColor {
        label: "Auto Color"
        description: "Follow the system theme primary color"
        inputType: SettingMeta.Switch
    }

    SettingMeta on ringWidth {
        label: "Ring Width"
        description: "Thickness of the expanding ripple ring"
        inputType: SettingMeta.Slider
        min: 0.05
        max: 0.8
        step: 0.01
    }

    SettingMeta on waveStrength {
        label: "Wave Shape"
        description: "Waviness/distortion strength of the boundary shape"
        inputType: SettingMeta.Slider
        min: 0.0
        max: 2.0
        step: 0.1
    }
}
