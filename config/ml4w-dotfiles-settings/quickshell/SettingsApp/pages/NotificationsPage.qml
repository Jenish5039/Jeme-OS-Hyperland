import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.CustomTheme
import "../components"

ColumnLayout {
    id: root

    spacing: 16
    Layout.fillWidth: true

    SectionHeader {
        title: "Notifications"
        subtitle: "Notification center controls, Do Not Disturb mode, and SwayNC notification daemon settings."
    }

    ActionCard {
        Layout.fillWidth: true
        title: "Toggle Notification Center"
        description: "Show or hide the SwayNC notification center panel and notification history."
        buttonText: "Open Panel"
        isPrimary: true
        onClicked: Quickshell.execDetached(["swaync-client", "-t", "-sw"])
    }

    ActionCard {
        Layout.fillWidth: true
        title: "Do Not Disturb (DND)"
        description: "Toggle Do Not Disturb mode to silence notification popups while you work or game."
        buttonText: "Toggle DND"
        onClicked: Quickshell.execDetached(["swaync-client", "-d", "-sw"])
    }

    ActionCard {
        Layout.fillWidth: true
        title: "SwayNC Configuration"
        description: "Open SwayNC's JSON configuration file in your default text editor."
        buttonText: "Edit config.json"
        onClicked: Quickshell.execDetached(["gnome-text-editor", Quickshell.env("HOME") + "/.config/swaync/config.json"])
    }

    // Information Card
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: infoColumn.implicitHeight + 28
        color: Theme.background
        border.color: Theme.primary
        border.width: 1
        radius: 10
        Layout.topMargin: 10

        ColumnLayout {
            id: infoColumn
            anchors.fill: parent
            anchors.margins: 16
            spacing: 8

            Text {
                text: "Notification Architecture"
                font.family: Theme.fontFamily
                font.pixelSize: 14
                font.bold: true
                color: Theme.primary
            }

            Text {
                text: "• Daemon: SwayNC (Sway Notification Center)\n• Control Command: swaync-client\n• Styling: Matugen colors dynamically injected into ~/.config/swaync/colors.css"
                font.family: Theme.fontFamily
                font.pixelSize: 12
                color: Theme.on_background
                opacity: 0.8
                lineHeight: 1.4
            }
        }
    }
}
