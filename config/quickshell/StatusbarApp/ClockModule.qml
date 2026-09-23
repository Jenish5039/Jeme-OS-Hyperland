import Quickshell
import QtQuick
import qs.CustomTheme

// Time displayed in the center of the bar; click toggles the calendar.
Item {
    id: clockRoot

    // Preserved for compatibility with parent bindings.
    property bool expanded: false
    // Qt date/time format for the time, supplied from statusbar.json.
    property string timeFormat: "HH:mm"
    // Preserved for compatibility with parent bindings.
    property string dateFormat: "ddd, dd MMM"
    // Set by the keyboard navigation in StatusbarWindow.
    property bool focused: false

    // Run the module's action (mouse click or keyboard Return).
    function activate(): void {
        Quickshell.execDetached(["qs", "ipc", "call", "calendar", "toggle"])
    }

    implicitWidth: timeText.implicitWidth + 24
    implicitHeight: timeText.implicitHeight

    // Highlight ring shown when selected via the keyboard. Wraps tightly around the time text.
    Rectangle {
        anchors.fill: timeText
        anchors.leftMargin: -7
        anchors.rightMargin: -7
        anchors.topMargin: -3
        anchors.bottomMargin: -3
        radius: 8
        color: "transparent"
        border.color: Theme.primary
        border.width: 1
        opacity: clockRoot.focused ? 1 : 0
        Behavior on opacity {
            NumberAnimation { duration: 150 }
        }
    }

    // Live clock, only ticks once per minute.
    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    // Click toggles the Calendar app via IPC.
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: Quickshell.execDetached(["qs", "ipc", "call", "calendar", "toggle"])
    }

    Text {
        id: timeText
        anchors.centerIn: parent
        text: Qt.formatDateTime(clock.date, clockRoot.timeFormat).replace(":", " : ")
        color: Theme.primary
        font.family: Theme.fontFamily
        font.pixelSize: 14
        font.bold: true
        font.letterSpacing: 1.2
    }
}
