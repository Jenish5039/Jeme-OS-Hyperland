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
        title: "Wallpaper"
        subtitle: "Manage desktop wallpaper, dynamic Matugen color generation, and visual effects."
    }

    ActionCard {
        Layout.fillWidth: true
        title: "Open Wallpaper Selector"
        description: "Launch the native Quickshell wallpaper browser to choose a wallpaper from your collection."
        buttonText: "Open Selector"
        isPrimary: true
        onClicked: Quickshell.execDetached(["qs", "ipc", "call", "wallpaper", "toggle"])
    }

    ActionCard {
        Layout.fillWidth: true
        title: "Random Wallpaper"
        description: "Pick and apply a random wallpaper from your configured wallpaper directory."
        buttonText: "Apply Random"
        onClicked: Quickshell.execDetached(["bash", "-c", Quickshell.env("HOME") + "/.config/ml4w/scripts/ml4w-wallpaper --random"])
    }

    ActionCard {
        Layout.fillWidth: true
        title: "Wallpaper Effects"
        description: "Select post-processing effects and filters to apply to your current wallpaper."
        buttonText: "Select Effects"
        onClicked: Quickshell.execDetached(["bash", "-c", Quickshell.env("HOME") + "/.config/ml4w/scripts/ml4w-wallpaper-effects"])
    }

    ActionCard {
        Layout.fillWidth: true
        title: "Clear Wallpaper Cache"
        description: "Regenerate wallpaper thumbnails and clear cached assets."
        buttonText: "Clear Cache"
        onClicked: Quickshell.execDetached(["bash", "-c", Quickshell.env("HOME") + "/.config/ml4w/scripts/ml4w-clear-wallpaper-cache"])
    }

    // Engine Info Card
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
            anchors.margins: 14
            spacing: 6

            Text {
                text: "Wallpaper Engine Details"
                font.family: Theme.fontFamily
                font.pixelSize: 14
                font.bold: true
                color: Theme.primary
            }

            Text {
                text: "• Daemon: awww (active Wayland wallpaper engine)\n• Theming: Matugen dynamic Material 3 color generation\n• Storage: ~/Pictures/Wallpapers"
                font.family: Theme.fontFamily
                font.pixelSize: 12
                color: Theme.on_background
                opacity: 0.8
                lineHeight: 1.3
            }
        }
    }
}
