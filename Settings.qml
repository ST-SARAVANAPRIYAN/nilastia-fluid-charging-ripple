import Nilastia.Plugins
import QtQuick

SettingsObject {
    property real waveSpeed: 1.0
    property real noiseStrength: 1.0
    property string rippleColor: "#8839ef"

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
}
