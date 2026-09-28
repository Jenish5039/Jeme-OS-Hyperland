import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import qs.CustomTheme

// Compact, real-time audio spectrum visualizer for the Jeme OS Statusbar.
// Driven by a persistent CAVA PipeWire raw stream in stereo mode.
//   • Stereo layout: 8 bars Left | 8 bars Right (bass rises in center)
//   • Adaptive dynamic scaling: normal music utilizes full 16px height
//   • Instant reaction: direct property binding (zero smoothing/sliding)
//   • Auto-hides on silence: collapses completely when no audio is playing
//   • Left click / Return  → Toggle native Quickshell audio popup
//   • Right click          → Open pwvucontrol / audio mixer
//   • Follows active Matugen color scheme (Theme.primary)
Rectangle {
    id: root

    // Keyboard navigation highlight flag (set by StatusbarWindow)
    property bool focused: false

    readonly property bool active: mouseArea.containsMouse || root.focused

    // Active audio detection: auto-collapse when silent so no idle dots show
    property bool hasAudio: false
    readonly property bool collapsed: !hasAudio

    // Bar layout specifications
    readonly property int barCount: 16
    readonly property real minBarHeight: 2.0
    readonly property real maxBarHeight: 16.0
    readonly property real barWidth: 2.5
    readonly property real barRadius: 1.25
    readonly property real barSpacing: 2.0

    // Adaptive peak tracking for dynamic range normalization (fast attack, decay floor at 45.0)
    property real visualPeak: 50.0

    // Raw spectrum values (0-100) from CAVA
    property var rawValues: [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]

    // Action execution (keyboard Return or mouse click)
    function activate(): void {
        Quickshell.execDetached(["qs", "ipc", "call", "audio", "toggle"])
    }

    implicitWidth: collapsed ? 0 : (barsRow.implicitWidth + 12)
    implicitHeight: 28
    radius: 14
    visible: !collapsed
    clip: true

    // Background pill matching BarButton and VolumeModule
    color: root.active ? Theme.primary : "transparent"

    Behavior on color {
        ColorAnimation { duration: 500; easing.type: Easing.OutQuint }
    }

    // Single persistent CAVA process streaming raw ASCII stereo frames
    Process {
        id: cavaProc
        command: [
            "stdbuf", "-oL", "-eL",
            "/home/zane/.local/bin/cava",
            "-p", Quickshell.env("HOME") + "/.config/cava/quickshell.conf"
        ]
        running: true

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                let str = data.trim()
                if (!str)
                    return
                let parts = str.split(";")
                let vals = []
                let hasSound = false
                let framePeak = 0

                for (let i = 0; i < root.barCount; i++) {
                    let num = (i < parts.length && parts[i] !== "") ? parseInt(parts[i]) || 0 : 0
                    vals.push(num)
                    if (num > 0)
                        hasSound = true
                    if (num > framePeak)
                        framePeak = num
                }

                if (hasSound) {
                    if (!root.hasAudio) {
                        root.hasAudio = true
                    }
                    // Adaptive dynamic-range scaling: instant attack on new peaks, smooth decay with noise-floor protection
                    if (framePeak > root.visualPeak) {
                        root.visualPeak = Math.min(100.0, framePeak)
                    } else {
                        root.visualPeak = Math.max(45.0, root.visualPeak * 0.98)
                    }
                    root.rawValues = vals
                    silenceTimer.restart()
                } else if (root.hasAudio) {
                    // Audio paused: set values to 0 directly
                    root.rawValues = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
                }
            }
        }

        onExited: (exitCode, exitStatus) => {
            // Self-heal and restart if CAVA exits unexpectedly
            restartTimer.restart()
        }
    }

    // Silence timer: after 1000ms of consecutive zero-levels, collapse the module
    Timer {
        id: silenceTimer
        interval: 1000
        repeat: false
        onTriggered: {
            root.hasAudio = false
            root.visualPeak = 50.0
            root.rawValues = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
        }
    }

    // Auto-restart timer for crash recovery
    Timer {
        id: restartTimer
        interval: 1500
        repeat: false
        onTriggered: {
            if (!cavaProc.running) {
                cavaProc.running = true
            }
        }
    }

    // Center container for bars
    Item {
        id: barsContainer
        anchors.centerIn: parent
        width: barsRow.implicitWidth
        height: root.maxBarHeight

        Row {
            id: barsRow
            anchors.bottom: parent.bottom
            spacing: root.barSpacing

            Repeater {
                model: root.barCount
                Rectangle {
                    required property int index
                    anchors.bottom: parent.bottom
                    width: root.barWidth
                    radius: root.barRadius
                    color: root.active ? Theme.background : Theme.primary

                    // Direct instant update with adaptive dynamic normalization
                    height: (root.rawValues && root.rawValues[index] !== undefined)
                        ? Math.max(root.minBarHeight, Math.min(root.maxBarHeight, (root.rawValues[index] / root.visualPeak) * root.maxBarHeight))
                        : root.minBarHeight

                    Behavior on color {
                        ColorAnimation { duration: 500; easing.type: Easing.OutQuint }
                    }
                }
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) {
                Quickshell.execDetached(["pwvucontrol"])
            } else {
                root.activate()
            }
        }
    }
}
