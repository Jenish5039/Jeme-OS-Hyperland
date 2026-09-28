import Quickshell
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import qs.CustomTheme

// Omarchy-inspired PipeWire volume module for Jeme OS.
//   • Left click / Return   → Toggle native Quickshell audio popup
//   • Right click           → Toggle audio mute
//   • Mouse wheel (hovered) → Raise/lower volume in 5% steps
//   • Up / Down arrows      → Adjust volume while keyboard-focused
//   • Dynamic multi-level icon (muted / low / high)
Rectangle {
    id: volume

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property bool ready: sink !== null && sink.ready && sink.audio !== null
    readonly property real level: ready ? sink.audio.volume : 0
    readonly property bool muted: ready ? sink.audio.muted : false
    readonly property int percent: muted ? 0 : Math.round(level * 100)

    readonly property real stepSize: 0.05
    property bool focused: false

    PwObjectTracker { objects: sink !== null ? [sink] : [] }

    function setVolume(v: real): void {
        if (!ready)
            return
        sink.audio.muted = false
        sink.audio.volume = Math.max(0, Math.min(1, v))
    }

    function step(dir: int): void {
        setVolume(level + dir * stepSize)
    }

    function toggleMute(): void {
        if (ready)
            sink.audio.muted = !sink.audio.muted
    }

    function activate(): void {
        Quickshell.execDetached(["qs", "ipc", "call", "audio", "toggle"])
    }

    readonly property string iconSource: {
        if (volume.percent <= 0 || volume.muted)
            return "../shared/icons/volume-muted.svg"
        if (volume.percent <= 45)
            return "../shared/icons/volume-low.svg"
        return "../shared/icons/volume.svg"
    }

    readonly property bool hovered: mouseArea.containsMouse
    readonly property bool active: hovered || volume.focused

    implicitWidth: row.implicitWidth + 16
    implicitHeight: 28
    radius: 14

    color: volume.focused ? Theme.primary : (hovered ? Theme.surface_container_high : "transparent")
    border.color: volume.focused ? Theme.primary : (hovered ? Theme.outline : "transparent")
    border.width: active ? 1 : 0

    Behavior on color {
        ColorAnimation { duration: 250; easing.type: Easing.OutQuint }
    }
    Behavior on border.color {
        ColorAnimation { duration: 250; easing.type: Easing.OutQuint }
    }
    Behavior on border.width {
        NumberAnimation { duration: 250; easing.type: Easing.OutQuint }
    }
    Behavior on implicitWidth {
        NumberAnimation { duration: 150; easing.type: Easing.OutQuint }
    }

    scale: mouseArea.pressed ? 0.94 : 1.0
    Behavior on scale {
        NumberAnimation { duration: 150; easing.type: Easing.OutBack }
    }

    // Keyboard selection ring
    Rectangle {
        anchors.fill: parent
        anchors.margins: -2
        radius: parent.radius + 2
        color: "transparent"
        border.color: Theme.primary
        border.width: 1.5
        opacity: volume.focused ? 1 : 0
        Behavior on opacity {
            NumberAnimation { duration: 150 }
        }
    }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 6

        Image {
            Layout.alignment: Qt.AlignVCenter
            source: volume.iconSource
            sourceSize.width: 16
            sourceSize.height: 16
            width: 16
            height: 16
            fillMode: Image.PreserveAspectFit
            layer.enabled: true
            layer.effect: MultiEffect {
                colorization: 1.0
                colorizationColor: volume.focused ? Theme.background : (volume.hovered ? Theme.on_surface : Theme.primary)
                Behavior on colorizationColor {
                    ColorAnimation { duration: 250; easing.type: Easing.OutQuint }
                }
            }
        }

        Text {
            Layout.alignment: Qt.AlignVCenter
            text: volume.percent + "%"
            color: volume.focused ? Theme.background : (volume.hovered ? Theme.on_surface : Theme.primary)
            font.family: Theme.fontFamily
            font.pixelSize: 13
            font.bold: true
            Behavior on color {
                ColorAnimation { duration: 250; easing.type: Easing.OutQuint }
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
            if (mouse.button === Qt.RightButton)
                volume.toggleMute()
            else
                volume.activate()
        }
        onWheel: wheel => volume.step(wheel.angleDelta.y > 0 ? 1 : -1)
    }
}
