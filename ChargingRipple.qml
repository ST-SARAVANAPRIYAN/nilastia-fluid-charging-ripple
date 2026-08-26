import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Nilastia.Config
import qs.components.containers
import qs.services
import Quickshell.Services.UPower

Variants {
    id: root
    model: Screens.screens

    property var settings: null

    StyledWindow {
        id: win
        required property ShellScreen modelData
        screen: modelData
        name: "charging-ripple"

        WlrLayershell.exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        surfaceFormat.opaque: false
        mask: Region {}

        anchors.top: true
        anchors.bottom: true
        anchors.left: true
        anchors.right: true

        Item {
            id: overlay
            anchors.fill: parent

            property color color: root.settings && root.settings.rippleColor ? root.settings.rippleColor : (Colours.palette.m3primary || "#8839ef")
            property int duration: root.settings && root.settings.waveSpeed ? (2200 / root.settings.waveSpeed) : 2200
            property int reverseDuration: root.settings && root.settings.waveSpeed ? (1600 / root.settings.waveSpeed) : 1600
            property real sparkleIntensity: root.settings && root.settings.noiseStrength !== undefined ? root.settings.noiseStrength : 1.0
            property real glowIntensity: 1.0
            property real ringWidth: 0.25

            // --- State ---
            property real progress: 0
            property real centerX: 0.5
            property real centerY: 1.0 // Start at bottom center (where cable plugs in)
            property bool playing: rippleAnim.running || rippleAnimReverse.running

            // Normalized distance calculation to ensure consistent expansion speed
            readonly property real maxDistance: {
                if (width <= 0 || height <= 0) return 1.0;
                const aspect = width / height;
                const dx0 = centerX * aspect;
                const dx1 = (1.0 - centerX) * aspect;
                const dy0 = centerY;
                const dy1 = (1.0 - centerY);

                return Math.max(
                    Math.sqrt(dx0*dx0 + dy0*dy0),
                    Math.sqrt(dx1*dx1 + dy0*dy0),
                    Math.sqrt(dx0*dx0 + dy1*dy1),
                    Math.sqrt(dx1*dx1 + dy1*dy1)
                );
            }

            ShaderEffect {
                id: shader
                anchors.fill: parent
                visible: overlay.playing

                property color color: overlay.color
                // Map 0-1 animation progress to the actual physical distance needed, scaled up to ensure it exits the screen
                property real progress: overlay.progress * overlay.maxDistance * 1.6
                property point center: Qt.point(overlay.centerX, overlay.centerY)
                property real aspect: width / height
                property real sparkleIntensity: overlay.sparkleIntensity
                property real glowIntensity: overlay.glowIntensity
                property real ringWidth: overlay.ringWidth

                fragmentShader: "FluidRipple.qsb"
            }

            NumberAnimation {
                id: rippleAnim
                target: overlay
                property: "progress"
                from: 0
                to: 1.0
                duration: overlay.duration
                easing.type: Easing.OutExpo
                onStarted: overlay.opacity = 1.0
                onFinished: overlay.progress = 0
            }

            SequentialAnimation {
                id: rippleAnimReverse

                ScriptAction {
                    script: {
                        overlay.opacity = 1.0;
                    }
                }

                ParallelAnimation {
                    NumberAnimation {
                        target: overlay
                        property: "progress"
                        from: 1.0
                        to: 0.0
                        duration: overlay.reverseDuration
                        easing.type: Easing.InCubic
                    }
                    NumberAnimation {
                        target: overlay
                        property: "opacity"
                        from: 1.0
                        to: 0.0
                        duration: overlay.reverseDuration
                        easing.type: Easing.InCubic
                    }
                }
            }

            function trigger() {
                console.log("[ChargingRipple] trigger() AOSP Shader ripple animation started!");
                rippleAnim.restart();
            }

            function triggerReverse() {
                console.log("[ChargingRipple] triggerReverse() AOSP Shader ripple animation started!");
                rippleAnimReverse.restart();
            }

            Connections {
                target: UPower
                function onOnBatteryChanged() {
                    console.log("[ChargingRipple] onOnBatteryChanged: UPower.onBattery =", UPower.onBattery);
                    if (!UPower.onBattery) {
                        overlay.trigger();
                    } else {
                        overlay.triggerReverse();
                    }
                }
            }

            IpcHandler {
                function trigger(): void {
                    console.log("[ChargingRipple] Triggered via IPC!");
                    overlay.trigger();
                }
                
                function triggerReverse(): void {
                    console.log("[ChargingRipple] Triggered reverse via IPC!");
                    overlay.triggerReverse();
                }
                
                target: "charging-ripple"
            }
        }
    }
}
