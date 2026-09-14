import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.CustomTheme
import "../components"

ColumnLayout {
    id: root

    property bool isInstalled: false

    spacing: 16
    Layout.fillWidth: true

    Process {
        command: ["bash", "-c", Quickshell.env("HOME") + "/.config/ml4w/scripts/ml4w-command-exists hyprmod"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                root.isInstalled = (this.text.trim() === "0");
            }
        }
    }

    SectionHeader {
        title: "HyprMod"
        subtitle: "Graphical configuration utility for fine-tuning Hyprland rules, monitors, animations, and behaviors."
    }

    // Status Banner Card
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 72
        color: Theme.background
        border.color: Theme.primary
        border.width: 1
        radius: 10

        RowLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 14

            Rectangle {
                Layout.preferredWidth: 38
                Layout.preferredHeight: 38
                radius: 19
                color: root.isInstalled ? Qt.rgba(0, 0.8, 0.4, 0.2) : Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.2)
                border.color: root.isInstalled ? "#00e676" : Theme.primary
                border.width: 1

                Rectangle {
                    anchors.centerIn: parent
                    width: 12
                    height: 12
                    radius: 6
                    color: root.isInstalled ? "#00e676" : Theme.primary
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    text: root.isInstalled ? "HyprMod is installed and ready" : "HyprMod is not installed"
                    font.family: Theme.fontFamily
                    font.pixelSize: 15
                    font.bold: true
                    color: Theme.on_background
                }

                Text {
                    text: root.isInstalled 
                        ? "Installed at ~/.local/bin/hyprmod. Click below to launch the interface." 
                        : "HyprMod can be installed to provide deeper graphical Hyprland customization."
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    color: Theme.on_background
                    opacity: 0.75
                }
            }
        }
    }

    ActionCard {
        Layout.fillWidth: true
        title: root.isInstalled ? "Launch HyprMod" : "Install HyprMod"
        description: "Open the HyprMod standalone configuration interface."
        buttonText: root.isInstalled ? "Launch Application" : "Run Installer"
        isPrimary: true
        onClicked: {
            if (root.isInstalled) {
                Quickshell.execDetached(["hyprmod"]);
            } else {
                Quickshell.execDetached(["kitty", "--class", "dotfiles-floating", "-e", Quickshell.env("HOME") + "/.config/ml4w/scripts/ml4w-install-hyprmod"]);
            }
        }
    }

    // Feature Highlights Card
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: featuresColumn.implicitHeight + 28
        color: Theme.background
        border.color: Theme.primary
        border.width: 1
        radius: 10
        Layout.topMargin: 10

        ColumnLayout {
            id: featuresColumn
            anchors.fill: parent
            anchors.margins: 16
            spacing: 8

            Text {
                text: "HyprMod Features"
                font.family: Theme.fontFamily
                font.pixelSize: 14
                font.bold: true
                color: Theme.primary
            }

            Text {
                text: "• Window Rules: Visual builder for floating, opacity, size, and pinning rules\n• Animations & Bezier Curves: Live preview of animation curves\n• Keybinding Editor: Modify and assign custom dispatcher hotkeys\n• Monitor Layouts: Fine-tune monitor position, scale, and transform parameters"
                font.family: Theme.fontFamily
                font.pixelSize: 12
                color: Theme.on_background
                opacity: 0.8
                lineHeight: 1.4
            }
        }
    }
}
