import QtQuick
import Quickshell
import Quickshell.Wayland
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
            visible: opacity > 0.0
            opacity: 0.0

            property real phase: 0.0
            property real waveHeightScale: 0.0 // Goes from 0.0 to 1.0
            property var particles: []

            // Trigger charging animation
            function trigger() {
                console.log("[ChargingRipple] trigger() animation started!");
                // Spawn particles
                let list = [];
                // Total particles: 100
                for (let i = 0; i < 100; i++) {
                    list.push({
                        x: Math.random() * win.width,
                        y: win.height + Math.random() * 50,
                        vx: (Math.random() - 0.5) * 4.0, // horizontal drift
                        vy: -2.0 - Math.random() * 6.0,  // upward velocity
                        radius: 2.0 + Math.random() * 5.0,
                        life: 1.0 + Math.random() * 1.5, // lifetime in seconds
                        maxLife: 1.0 + Math.random() * 1.5,
                        sparkleSpeed: 5.0 + Math.random() * 10.0,
                        phase: Math.random() * Math.PI * 2
                    });
                }
                particles = list;
                phase = 0.0;
                waveHeightScale = 0.0;
                
                // Play animations
                fadeInOut.restart();
            }

            function updateParticles() {
                let list = [];
                for (let i = 0; i < particles.length; i++) {
                    let p = particles[i];
                    p.life -= 0.016; // 16ms delta
                    if (p.life > 0) {
                        p.x += p.vx;
                        p.y += p.vy;
                        // Add organic wobble
                        p.x += Math.sin(phase * p.sparkleSpeed + p.phase) * 0.5;
                        list.push(p);
                    }
                }
                particles = list;
            }

            SequentialAnimation {
                id: fadeInOut

                // 1. Swell wave and fade in overlay
                ParallelAnimation {
                    NumberAnimation {
                        target: overlay
                        property: "opacity"
                        to: 1.0
                        duration: 500
                        easing.type: Easing.OutQuad
                    }
                    NumberAnimation {
                        target: overlay
                        property: "waveHeightScale"
                        to: 1.0
                        duration: 1200
                        easing.type: Easing.OutBack
                    }
                }

                // 2. Sustain briefly while sparkles drift up
                PauseAnimation {
                    duration: 1200
                }

                // 3. Fall back down and fade out
                ParallelAnimation {
                    NumberAnimation {
                        target: overlay
                        property: "opacity"
                        to: 0.0
                        duration: 800
                        easing.type: Easing.InQuad
                    }
                    NumberAnimation {
                        target: overlay
                        property: "waveHeightScale"
                        to: 0.0
                        duration: 1000
                        easing.type: Easing.InQuad
                    }
                }
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

            Timer {
                id: animTimer
                interval: 16
                running: overlay.visible && overlay.opacity > 0.0
                repeat: true
                onTriggered: {
                    overlay.phase += 0.05;
                    overlay.updateParticles();
                    canvas.requestPaint();
                }
            }

            Canvas {
                id: canvas
                anchors.fill: parent
                renderTarget: Canvas.FramebufferObject

                onPaint: {
                    let ctx = canvas.getContext("2d");
                    ctx.clearRect(0, 0, canvas.width, canvas.height);

                    let pColor = Colours.palette.m3primary || "#8839ef";
                    let pContainerColor = Colours.palette.m3primaryContainer || "#e6e9ef";

                    let baseHeight = 100.0 * overlay.waveHeightScale;
                    if (baseHeight <= 0) return;

                    // --- 1. Draw Back Wave ---
                    ctx.save();
                    ctx.fillStyle = pContainerColor;
                    ctx.globalAlpha = 0.35 * overlay.opacity;
                    ctx.beginPath();
                    ctx.moveTo(0, canvas.height);
                    
                    for (let x = 0; x <= canvas.width; x += 10) {
                        let y = canvas.height - baseHeight + 
                                Math.sin(x * 0.006 + overlay.phase * 0.8) * 15 * overlay.waveHeightScale - 
                                Math.cos(x * 0.003 - overlay.phase * 0.5) * 8 * overlay.waveHeightScale;
                        ctx.lineTo(x, y);
                    }
                    ctx.lineTo(canvas.width, canvas.height);
                    ctx.closePath();
                    ctx.fill();
                    ctx.restore();

                    // --- 2. Draw Front Wave (with glow effect) ---
                    ctx.save();
                    ctx.fillStyle = pColor;
                    ctx.globalAlpha = 0.55 * overlay.opacity;
                    
                    // Subtle glowing drop shadow for premium depth
                    ctx.shadowColor = pColor;
                    ctx.shadowBlur = 25 * overlay.waveHeightScale;
                    
                    ctx.beginPath();
                    ctx.moveTo(0, canvas.height);
                    for (let x = 0; x <= canvas.width; x += 10) {
                        let y = canvas.height - baseHeight + 
                                Math.sin(x * 0.008 + overlay.phase * 1.2) * 12 * overlay.waveHeightScale + 
                                Math.cos(x * 0.004 + overlay.phase * 0.9) * 10 * overlay.waveHeightScale;
                        ctx.lineTo(x, y);
                    }
                    ctx.lineTo(canvas.width, canvas.height);
                    ctx.closePath();
                    ctx.fill();
                    ctx.restore();

                    // --- 3. Draw Sparkle Particles ---
                    ctx.save();
                    let pts = overlay.particles;
                    for (let i = 0; i < pts.length; i++) {
                        let p = pts[i];
                        let ratio = p.life / p.maxLife;
                        
                        // Particle fade out
                        ctx.globalAlpha = ratio * overlay.opacity;
                        
                        // Micro-sparkle breathing scale
                        let size = p.radius * (0.8 + Math.sin(overlay.phase * p.sparkleSpeed) * 0.3);

                        // Draw glowing sparkle particle
                        ctx.shadowColor = pColor;
                        ctx.shadowBlur = 10;
                        ctx.fillStyle = pColor;
                        
                        ctx.beginPath();
                        ctx.arc(p.x, p.y, size, 0, Math.PI * 2);
                        ctx.fill();
                    }
                    ctx.restore();
                }
            }
        }
    }
}
