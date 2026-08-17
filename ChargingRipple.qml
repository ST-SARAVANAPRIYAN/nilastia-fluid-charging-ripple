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

        anchors.top: true
        anchors.bottom: true
        anchors.left: true
        anchors.right: true

        Item {
            id: overlay
            anchors.fill: parent
            visible: rippleAnim.running

            // Spawns at bottom center (where battery charging ripple typically starts)
            Rectangle {
                id: ripple
                anchors.bottom: parent.bottom
                anchors.bottomMargin: -height / 2
                anchors.horizontalCenter: parent.horizontalCenter

                width: 150
                height: 150
                radius: 75
                
                color: Colours.palette.m3primary || "#8839ef"
                opacity: 0.0
                scale: 1.0
            }

            SequentialAnimation {
                id: rippleAnim

                ParallelAnimation {
                    NumberAnimation {
                        target: ripple
                        property: "scale"
                        from: 0.1
                        to: 25.0
                        duration: 1500
                        easing.type: Easing.OutQuart
                    }
                    NumberAnimation {
                        target: ripple
                        property: "opacity"
                        from: 0.5
                        to: 0.0
                        duration: 1500
                        easing.type: Easing.OutQuart
                    }
                }
            }

            function trigger() {
                console.log("[ChargingRipple] trigger() basic rounded ripple animation started!");
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
