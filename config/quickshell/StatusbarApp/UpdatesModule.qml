import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import qs.CustomTheme

// Omarchy-styled system update indicator for Jeme OS.
// Displays the number of pending package updates next to a package icon.
// Auto-collapses when 0 updates are pending.
Rectangle {
    id: updates

    property int count: 0
    readonly property bool collapsed: count <= 0
    property bool focused: false

    function activate(): void {
        Quickshell.execDetached(["bash", "-c",
            Quickshell.env("HOME") + "/.config/ml4w/settings/installupdates.sh"])
    }

    visible: !collapsed

    readonly property bool hovered: mouseArea.containsMouse
    readonly property bool active: hovered || updates.focused

    implicitWidth: collapsed ? 0 : row.implicitWidth + 16
    implicitHeight: 28
    radius: 14

    color: updates.focused ? Theme.primary : (hovered ? Theme.surface_container_highest : "transparent")
    border.color: updates.focused ? Theme.primary : (hovered ? Theme.outline : "transparent")
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
        opacity: updates.focused ? 1 : 0
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
            source: "../shared/icons/package.svg"
            sourceSize.width: 16
            sourceSize.height: 16
            width: 16
            height: 16
            fillMode: Image.PreserveAspectFit
            layer.enabled: true
            layer.effect: MultiEffect {
                colorization: 1.0
                colorizationColor: updates.focused ? Theme.background : (updates.hovered ? Theme.on_surface : Theme.primary)
                Behavior on colorizationColor {
                    ColorAnimation { duration: 250; easing.type: Easing.OutQuint }
                }
            }
        }

        Text {
            Layout.alignment: Qt.AlignVCenter
            text: updates.count
            color: updates.focused ? Theme.background : (updates.hovered ? Theme.on_surface : Theme.primary)
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
        cursorShape: Qt.PointingHandCursor
        onClicked: updates.activate()
    }

    function refresh(): void {
        updatesProc.running = false
        updatesProc.running = true
    }

    Process {
        id: updatesProc
        command: ["bash", "-c",
            Quickshell.env("HOME") + "/.config/ml4w/scripts/ml4w-check-system-updates"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let raw = this.text.trim()
                    updates.count = raw ? parseInt(JSON.parse(raw).text) || 0 : 0
                } catch (e) {
                    updates.count = 0
                }
            }
        }
    }

    // Initial check deferred by 8 seconds so dnf check-update does not contend with desktop startup
    Timer {
        interval: 8000
        running: true
        repeat: false
        onTriggered: updates.refresh()
    }

    // Re-check on the same 1800s interval as the Waybar module
    Timer {
        interval: 1800 * 1000
        running: true
        repeat: true
        onTriggered: updates.refresh()
    }

    IpcHandler {
        target: "updates"
        function reset(): void { updates.count = 0 }
        function refresh(): void { updates.refresh() }
    }
}
