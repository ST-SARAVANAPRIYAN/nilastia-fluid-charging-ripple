import QtQuick
import QtQuick.Layouts
import Nilastia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus.common
import Quickshell
import Quickshell.Io

ColumnLayout {
    id: root
    spacing: Tokens.spacing.medium

    property var settings

    // Helper menu items for the Animation Type dropdown (Fade removed as requested)
    readonly property list<MenuItem> animationTypeItems: [
        MenuItem { text: "Out Expo (Default)"; value: "out-expo" },
        MenuItem { text: "Ease In Out"; value: "in-out-quad" },
        MenuItem { text: "Ease Out"; value: "ease-out" },
        MenuItem { text: "Linear"; value: "linear" }
    ]

    Process {
        id: previewTrigger
        command: ["qs", "-c", "niri-nilastia-shell", "ipc", "call", "charging-ripple", "trigger"]
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 1

        // Slider for Wave Speed (mapped 0.1 to 5.0)
        SliderRow {
            first: true
            label: "Wave Speed"
            value: (settings.waveSpeed - 0.1) / 4.9
            valueLabel: settings.waveSpeed.toFixed(1)
            onMoved: v => settings.waveSpeed = 0.1 + v * 4.9
        }

        // Slider for Sparkle Intensity (mapped 0.0 to 3.0)
        SliderRow {
            label: "Sparkle Intensity"
            value: settings.noiseStrength / 3.0
            valueLabel: settings.noiseStrength.toFixed(1)
            onMoved: v => settings.noiseStrength = v * 3.0
        }

        // Slider for Wave Shape / Waviness Strength (mapped 0.0 to 2.0)
        SliderRow {
            label: "Wave Shape"
            value: settings.waveStrength / 2.0
            valueLabel: settings.waveStrength.toFixed(1)
            onMoved: v => settings.waveStrength = v * 2.0
        }

        // Slider for Ring Width (mapped 0.05 to 0.8)
        SliderRow {
            label: "Ring Width"
            value: (settings.ringWidth - 0.05) / 0.75
            valueLabel: settings.ringWidth.toFixed(2)
            onMoved: v => settings.ringWidth = 0.05 + v * 0.75
        }

        // Dropdown for Animation Type
        SelectRow {
            label: "Animation Type"
            subtext: "Transition curve for the expansion"
            menuItems: root.animationTypeItems
            active: {
                const t = settings.animationType || "out-expo";
                for (let i = 0; i < root.animationTypeItems.length; i++) {
                    if (root.animationTypeItems[i].value === t) {
                        return root.animationTypeItems[i];
                    }
                }
                return root.animationTypeItems[0];
            }
            onSelected: item => {
                settings.animationType = item.value;
            }
        }

        // Auto Color Toggle
        ToggleRow {
            text: "Auto Color"
            subtext: "Dynamically follow the system theme accent color"
            checked: settings.autoColor
            onToggled: settings.autoColor = checked
        }

        // Ripple Color Field (RowButton with inline text field or simple text field row)
        ConnectedRect {
            implicitHeight: rowLayout.implicitHeight + Tokens.padding.large * 2
            Layout.fillWidth: true
            opacity: settings.autoColor ? 0.5 : 1.0

            RowLayout {
                id: rowLayout
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: Tokens.padding.largeIncreased
                anchors.rightMargin: Tokens.padding.largeIncreased
                spacing: Tokens.spacing.medium

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    StyledText {
                        text: "Ripple Color"
                        font: Tokens.font.body.small
                        color: settings.autoColor ? Colours.palette.m3outline : Colours.palette.m3onSurface
                    }
                    StyledText {
                        text: "Hex color code for the fluid"
                        font: Tokens.font.label.small
                        color: Colours.palette.m3outline
                    }
                }

                StyledTextField {
                    Layout.preferredWidth: 100
                    text: settings.rippleColor
                    enabled: !settings.autoColor
                    onEditingFinished: settings.rippleColor = text
                }
            }
        }

        // Preview Test Button
        RowButton {
            text: "Preview Test Animation"
            subtext: "Click to play the ripple effect live"
            icon: "play_arrow"
            onClicked: {
                previewTrigger.running = true;
            }
        }

        // Reset to Defaults Button
        RowButton {
            last: true
            text: "Reset to Defaults"
            subtext: "Restore original values"
            icon: "settings_backup_restore"
            onClicked: {
                settings.waveSpeed = 1.0;
                settings.noiseStrength = 1.0;
                settings.rippleColor = "#8839ef";
                settings.animationType = "out-expo";
                settings.autoColor = true;
                settings.ringWidth = 0.25;
                settings.waveStrength = 1.0;
            }
        }
    }
}
