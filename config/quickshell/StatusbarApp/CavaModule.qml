import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import qs.CustomTheme

// Compact, real-time audio spectrum visualizer for the Jeme OS Statusbar.
// Driven by a persistent CAVA PipeWire raw stream.
//   • Auto-hides on silence: collapses completely when no audio is playing (zero idle dots)
//   • Rises and fades up from the bottom when sound begins
//   • Sinks down and fades out when sound ends
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
    readonly property real minBarHeight: 0.0
    readonly property real maxBarHeight: 16.0
    readonly property real barWidth: 2.5
    readonly property real barRadius: 1.25
    readonly property real barSpacing: 2.0

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

    Behavior on implicitWidth {
        NumberAnimation { duration: 320; easing.type: Easing.OutQuint }
    }

    // Background pill matching BarButton and VolumeModule
    color: root.active ? Theme.primary : "transparent"

    Behavior on color {
        ColorAnimation { duration: 500; easing.type: Easing.OutQuint }
    }

    // Single persistent CAVA process streaming raw ASCII frames
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
                for (let i = 0; i < root.barCount; i++) {
                    let num = (i < parts.length && parts[i] !== "") ? parseInt(parts[i]) || 0 : 0
                    vals.push(num)
                    if (num > 0)
                        hasSound = true
                }

                if (hasSound) {
                    if (!root.hasAudio) {
                        root.hasAudio = true
                    }
                    root.rawValues = vals
                    silenceTimer.restart()
                } else if (root.hasAudio) {
                    // Audio just paused or quiet: let bars decay smoothly to 0
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

    // Center container for bars with vertical slide/fade-from-down transition
    Item {
        id: barsContainer
        anchors.centerIn: parent
        width: barsRow.implicitWidth
        height: root.maxBarHeight

        // Fade in from below: opacity + upward translation
        opacity: root.hasAudio ? 1.0 : 0.0
        transform: Translate {
            y: root.hasAudio ? 0 : 10
            Behavior on y {
                NumberAnimation {
                    duration: 350
                    easing.type: Easing.OutQuint
                }
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: 300
                easing.type: Easing.OutQuint
            }
        }

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

                    // Target height calculated from spectrum value (0-100)
                    property real targetHeight: {
                        let v = (root.rawValues && root.rawValues[index] !== undefined)
                            ? root.rawValues[index] : 0
                        return Math.max(root.minBarHeight, (v / 100.0) * root.maxBarHeight)
                    }

                    height: targetHeight

                    // Silky-smooth 144Hz height animation rising upwards from bottom
                    Behavior on height {
                        NumberAnimation {
                            duration: 90
                            easing.type: Easing.OutCubic
                        }
                    }

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
