import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../CustomTheme"
import "../components"

ColumnLayout {
    id: root

    spacing: 16
    Layout.fillWidth: true

    SectionHeader {
        title: "About Jeme OS"
        subtitle: "Distribution identity, core architecture specifications, system diagnostics, and community resources."
    }

    // Identity Card
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 140
        color: Theme.surface_container
        border.color: Theme.outline_variant
        border.width: 1
        radius: 10

        RowLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 20

            Image {
                source: "file://" + Quickshell.env("HOME") + "/.config/my-logo/logo.svg"
                sourceSize.width: 64
                sourceSize.height: 64
                Layout.preferredWidth: 64
                Layout.preferredHeight: 64
                fillMode: Image.PreserveAspectFit
                Layout.alignment: Qt.AlignVCenter
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 4

                Text {
                    text: "Jeme OS"
                    font.family: Theme.fontFamily
                    font.pixelSize: 22
                    font.bold: true
                    color: Theme.on_surface
                }

                Text {
                    text: "Version 2.15.1"
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    font.bold: true
                    color: Theme.primary
                }

                Text {
                    text: "An intentional, keyboard-driven Linux desktop rice combining the speed of Hyprland with reactive Quickshell widgets and Matugen dynamic color synchronization."
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    color: Theme.on_surface_variant
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }
        }
    }

    Text {
        text: "Desktop Stack Specifications"
        font.family: Theme.fontFamily
        font.pixelSize: 16
        font.bold: true
        color: Theme.primary
        Layout.topMargin: 5
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: stackColumn.implicitHeight + 28
        color: Theme.surface_container
        border.color: Theme.outline_variant
        border.width: 1
        radius: 10

        ColumnLayout {
            id: stackColumn
            anchors.fill: parent
            anchors.margins: 16
            spacing: 8

            Repeater {
                model: ListModel {
                    ListElement { label: "Base Operating System"; val: "Fedora Linux (x86_64)" }
                    ListElement { label: "Wayland Compositor"; val: "Hyprland (Native Lua API)" }
                    ListElement { label: "Desktop Shell & Widgets"; val: "Quickshell (QML / Qt6)" }
                    ListElement { label: "Color Generation Engine"; val: "Matugen (Material Design 3)" }
                    ListElement { label: "Wallpaper Daemon"; val: "awww" }
                    ListElement { label: "Notification Daemon"; val: "SwayNC" }
                    ListElement { label: "Sound Architecture"; val: "PipeWire + WirePlumber" }
                }

                delegate: RowLayout {
                    Layout.fillWidth: true
                    spacing: 16

                    Text {
                        text: model.label
                        font.family: Theme.fontFamily
                        font.bold: true
                        font.pixelSize: 13
                        color: Theme.primary
                        Layout.preferredWidth: 200
                    }

                    Text {
                        text: model.val
                        font.family: Theme.fontFamily
                        font.pixelSize: 13
                        color: Theme.on_surface
                        Layout.fillWidth: true
                    }
                }
            }
        }
    }

    ActionCard {
        Layout.fillWidth: true
        title: "Hardware & System Information"
        description: "Launch terminal system specifications and Neofetch/Fastfetch hardware summary."
        buttonText: "Open Fastfetch"
        isPrimary: true
        onClicked: Quickshell.execDetached(["bash", "-c", Quickshell.env("HOME") + "/.config/ml4w/scripts/ml4w-hyprsysteminfo"])
    }
}
