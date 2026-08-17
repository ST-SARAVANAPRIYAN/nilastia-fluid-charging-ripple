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

            // --- Configuration ---
            property color color: Colours.palette.m3primary || "#8839ef"
            property int duration: 1000
            property real sparkleIntensity: 1.0
            property real glowIntensity: 1.0
            property real ringWidth: 0.15

            // --- State ---
            property real progress: 0
            property real centerX: 0.5
            property real centerY: 1.0 // Start at bottom center (where cable plugs in)
            property bool playing: progress > 0 && progress < 1.0

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
                onFinished: overlay.progress = 0
            }

            function trigger() {
                console.log("[ChargingRipple] trigger() AOSP Shader ripple animation started!");
                rippleAnim.restart();
            }

            Connections {
                target: UPower
                function onOnBatteryChanged() {
                    console.log("[ChargingRipple] onOnBatteryChanged: UPower.onBattery =", UPower.onBattery);
                    if (!UPower.onBattery) {
                        overlay.trigger();
                    }
                }
            }

            IpcHandler {
                function trigger(): void {
                    console.log("[ChargingRipple] Triggered via IPC!");
                    overlay.trigger();
                }
                target: "charging-ripple"
            }
        }
    }
}
