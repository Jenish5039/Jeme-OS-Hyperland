import Quickshell
import QtQuick
import qs.CustomTheme

// Omarchy-inspired Clock & Date module for Jeme OS.
//   • Left click / Return  → Toggle native Quickshell Calendar popup
//   • Right click          → Cycle through 4 date/time display formats
//   • Zero-wake design     → Ticks per-minute by default; seconds only when active format demands it
Rectangle {
    id: clockRoot

    // Preserved for compatibility with parent bindings
    property bool expanded: false
    // Formats supplied from statusbar.json
    property string timeFormat: "HH:mm"
    property string dateFormat: "ddd, dd MMM"
    // Set by StatusbarWindow keyboard navigation
    property bool focused: false

    // Available formats ring
    readonly property var formats: [
        clockRoot.timeFormat,
        clockRoot.dateFormat,
        "HH:mm:ss",
        "ddd, HH:mm"
    ]
    property int formatIndex: 0
    readonly property string activeFormat: formats[formatIndex % formats.length]
    readonly property bool needsSeconds: activeFormat.indexOf("ss") !== -1

    function cycleFormat(): void {
        formatIndex = (formatIndex + 1) % formats.length
    }

    // Run primary action (left click or keyboard Return)
    function activate(): void {
        Quickshell.execDetached(["qs", "ipc", "call", "calendar", "toggle"])
    }

    readonly property bool hovered: mouseArea.containsMouse
    readonly property bool active: hovered || clockRoot.focused

    implicitWidth: timeText.implicitWidth + 20
    implicitHeight: 28
    radius: 14

    color: clockRoot.focused ? Theme.primary : (hovered ? Theme.surface_container_high : "transparent")
    border.color: clockRoot.focused ? Theme.primary : (hovered ? Theme.outline : "transparent")
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
        NumberAnimation { duration: 200; easing.type: Easing.OutQuint }
    }

    scale: mouseArea.pressed ? 0.94 : 1.0
    Behavior on scale {
        NumberAnimation { duration: 150; easing.type: Easing.OutBack }
    }

    // Dynamic system clock: only ticks per-second when active format has seconds
    SystemClock {
        id: clock
        precision: clockRoot.needsSeconds ? SystemClock.Seconds : SystemClock.Minutes
    }

    // Highlight ring shown when keyboard-focused
    Rectangle {
        anchors.fill: parent
        anchors.margins: -2
        radius: parent.radius + 2
        color: "transparent"
        border.color: Theme.primary
        border.width: 1.5
        opacity: clockRoot.focused ? 1 : 0
        Behavior on opacity {
            NumberAnimation { duration: 150 }
        }
    }

    Text {
        id: timeText
        anchors.centerIn: parent
        text: {
            let str = Qt.formatDateTime(clock.date, clockRoot.activeFormat)
            if (clockRoot.activeFormat === "HH:mm")
                return str.replace(":", " : ")
            return str
        }
        color: clockRoot.focused ? Theme.background : (hovered ? Theme.on_surface : Theme.primary)
        font.family: Theme.fontFamily
        font.pixelSize: 13
        font.bold: true
        font.letterSpacing: 1.1

        Behavior on color {
            ColorAnimation { duration: 250; easing.type: Easing.OutQuint }
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
                clockRoot.cycleFormat()
            } else {
                clockRoot.activate()
            }
        }
    }
}
