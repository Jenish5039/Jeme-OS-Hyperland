import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "../../CustomTheme"
import "../components"

ColumnLayout {
    id: root

    property string scriptPath: Quickshell.env("HOME") + "/.local/bin/ml4w-dotfiles-settings"
    property string profile: "com.ml4w.dotfiles"
    property bool isHyprlandSettingsInstalled: false
    signal navigateTo(int pageIndex)

    spacing: 20
    Layout.fillWidth: true

    // Check HyprMod installed
    Process {
        command: ["bash", "-c", Quickshell.env("HOME") + "/.config/ml4w/scripts/ml4w-command-exists hyprmod"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                root.isHyprlandSettingsInstalled = (this.text.trim() === "0");
            }
        }
    }

    // --- HERO SECTION ---
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 160
        implicitHeight: 160
        color: Theme.surface_container
        border.color: Theme.outline_variant
        border.width: 1
        radius: 12

        RowLayout {
            anchors.fill: parent
            anchors.margins: 24
            spacing: 24

            Image {
                source: "file://" + Quickshell.env("HOME") + "/.config/my-logo/logo.svg"
                sourceSize.width: 76
                sourceSize.height: 76
                Layout.preferredWidth: 76
                Layout.preferredHeight: 76
                fillMode: Image.PreserveAspectFit
                Layout.alignment: Qt.AlignVCenter
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 6

                Text {
                    text: "Welcome to Jeme OS"
                    font.family: Theme.fontFamily
                    font.pixelSize: 24
                    font.bold: true
                    color: Theme.on_surface
                }

                Text {
                    text: "Version 2.15.1 — Fedora Linux • Hyprland • Quickshell"
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    font.bold: true
                    color: Theme.primary
                }

                Text {
                    text: "Unified system control center. Configure appearance, window rules, displays, and desktop defaults in one place."
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    color: Theme.on_surface_variant
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }
        }
    }

    // --- QUICK ACTIONS ---
    Text {
        text: "Quick Actions"
        font.family: Theme.fontFamily
        font.pixelSize: 16
        font.bold: true
        color: Theme.primary
        Layout.topMargin: 5
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 12

        // HyprMod
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 50
            radius: 8
            color: mouseAreaHyprMod.containsMouse ? Theme.surface_container_highest : Theme.surface_container_high
            border.color: mouseAreaHyprMod.containsMouse ? Theme.primary : Theme.outline_variant
            border.width: 1

            Behavior on color { ColorAnimation { duration: 150 } }
            Behavior on border.color { ColorAnimation { duration: 150 } }

            RowLayout {
                anchors.fill: parent
                anchors.margins: 12

                Text {
                    text: root.isHyprlandSettingsInstalled ? "Launch HyprMod" : "Install HyprMod"
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    font.bold: true
                    color: Theme.primary
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    Layout.fillWidth: true
                }
            }

            MouseArea {
                id: mouseAreaHyprMod
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (root.isHyprlandSettingsInstalled) {
                        Quickshell.execDetached(["hyprmod"]);
                    } else {
                        Quickshell.execDetached(["kitty", "--class", "dotfiles-floating", "-e", Quickshell.env("HOME") + "/.config/ml4w/scripts/ml4w-install-hyprmod"]);
                    }
                }
            }
        }

        // Displays
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 50
            radius: 8
            color: mouseAreaDisplays.containsMouse ? Theme.surface_container_highest : Theme.surface_container_high
            border.color: mouseAreaDisplays.containsMouse ? Theme.primary : Theme.outline_variant
            border.width: 1

            Behavior on color { ColorAnimation { duration: 150 } }
            Behavior on border.color { ColorAnimation { duration: 150 } }

            RowLayout {
                anchors.fill: parent
                anchors.margins: 12

                Text {
                    text: "Displays"
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    font.bold: true
                    color: Theme.primary
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    Layout.fillWidth: true
                }
            }

            MouseArea {
                id: mouseAreaDisplays
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Quickshell.execDetached(["nwg-displays"])
            }
        }

        // Appearance
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 50
            radius: 8
            color: mouseAreaTheme.containsMouse ? Theme.surface_container_highest : Theme.surface_container_high
            border.color: mouseAreaTheme.containsMouse ? Theme.primary : Theme.outline_variant
            border.width: 1

            Behavior on color { ColorAnimation { duration: 150 } }
            Behavior on border.color { ColorAnimation { duration: 150 } }

            RowLayout {
                anchors.fill: parent
                anchors.margins: 12

                Text {
                    text: "Theme Manager"
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    font.bold: true
                    color: Theme.primary
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    Layout.fillWidth: true
                }
            }

            MouseArea {
                id: mouseAreaTheme
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Quickshell.execDetached(["nwg-look"])
            }
        }

        // Wallpaper Selector
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 50
            radius: 8
            color: mouseAreaWallpaper.containsMouse ? Theme.surface_container_highest : Theme.surface_container_high
            border.color: mouseAreaWallpaper.containsMouse ? Theme.primary : Theme.outline_variant
            border.width: 1

            Behavior on color { ColorAnimation { duration: 150 } }
            Behavior on border.color { ColorAnimation { duration: 150 } }

            RowLayout {
                anchors.fill: parent
                anchors.margins: 12

                Text {
                    text: "Wallpaper"
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    font.bold: true
                    color: Theme.primary
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    Layout.fillWidth: true
                }
            }

            MouseArea {
                id: mouseAreaWallpaper
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Quickshell.execDetached(["qs", "ipc", "call", "wallpaper", "toggle"])
            }
        }
    }

    // --- KEYBINDING CHEAT SHEET ---
    Text {
        text: "Keyboard Shortcuts"
        font.family: Theme.fontFamily
        font.pixelSize: 16
        font.bold: true
        color: Theme.primary
        Layout.topMargin: 10
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: keybindColumn.implicitHeight + 36
        color: Theme.surface_container
        border.color: Theme.outline_variant
        border.width: 1
        radius: 10

        ColumnLayout {
            id: keybindColumn
            anchors.fill: parent
            anchors.margins: 18
            spacing: 10

            Repeater {
                model: ListModel {
                    ListElement { keys: "Super + Enter"; desc: "Open terminal" }
                    ListElement { keys: "Super + B"; desc: "Open web browser" }
                    ListElement { keys: "Super + Q"; desc: "Close active window" }
                    ListElement { keys: "Super + CTRL + Enter"; desc: "Open application launcher" }
                    ListElement { keys: "Super + CTRL + S"; desc: "Open desktop sidebar" }
                    ListElement { keys: "Super + CTRL + W"; desc: "Open wallpaper selector" }
                    ListElement { keys: "Super + ,"; desc: "Open Settings" }
                }

                delegate: RowLayout {
                    Layout.fillWidth: true
                    spacing: 16

                    Rectangle {
                        Layout.preferredWidth: 160
                        Layout.preferredHeight: 28
                        radius: 6
                        color: Theme.surface_container_highest
                        border.color: Theme.outline_variant
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: model.keys
                            font.family: Theme.fontFamily
                            font.bold: true
                            font.pixelSize: 12
                            color: Theme.primary
                        }
                    }

                    Text {
                        text: model.desc
                        font.family: Theme.fontFamily
                        font.pixelSize: 13
                        color: Theme.on_surface
                        Layout.fillWidth: true
                    }
                }
            }

            Button {
                id: allKeybindsBtn
                Layout.alignment: Qt.AlignRight
                Layout.topMargin: 8
                text: "All Keybindings..."
                hoverEnabled: true

                contentItem: Text {
                    text: allKeybindsBtn.text
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    font.bold: true
                    color: Theme.primary
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    leftPadding: 14
                    rightPadding: 14
                    topPadding: 6
                    bottomPadding: 6
                }

                background: Rectangle {
                    radius: 6
                    color: allKeybindsBtn.hovered ? Theme.surface_container_highest : Theme.surface_container_high
                    border.color: Theme.outline_variant
                    border.width: 1
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.NoButton
                }

                onClicked: {
                    Quickshell.execDetached(["bash", "-c", Quickshell.env("HOME") + "/.config/hypr/scripts/keybindings.sh"]);
                }
            }
        }
    }

    // --- WINDOW & STARTUP PREFERENCES ---
    Text {
        text: "Window & Startup Preferences"
        font.family: Theme.fontFamily
        font.pixelSize: 16
        font.bold: true
        color: Theme.primary
        Layout.topMargin: 10
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 12

        ActionCard {
            Layout.fillWidth: true
            title: "Toggle Window Mode"
            description: "Switch current window between floating and tiled mode."
            buttonText: "Toggle Float"
            onClicked: {
                if (Hyprland.usingLua)
                    Hyprland.dispatch("hl.dsp.window.float({ action = 'toggle' })");
                else
                    Hyprland.dispatch("togglefloating");
            }
        }

        SettingsCard {
            Layout.fillWidth: true
            title: "Show on Startup"
            instructions: "Automatically open Settings overview when logging into Jeme OS."

            Switch {
                id: autostartSwitch
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                hoverEnabled: true

                property bool ready: false

                Process {
                    command: ["bash", "-c", "test -f ~/.cache/ml4w-welcome-autostart && echo exists || echo missing"]
                    running: true
                    stdout: StdioCollector {
                        onStreamFinished: {
                            var output = this.text.trim();
                            autostartSwitch.checked = (output !== "exists");
                            autostartSwitch.ready = true;
                        }
                    }
                }

                indicator: Rectangle {
                    implicitWidth: 48
                    implicitHeight: 26
                    radius: 13
                    color: autostartSwitch.checked ? Theme.primary : Theme.surface_container_highest
                    border.color: autostartSwitch.checked ? Theme.primary : Theme.outline
                    border.width: 1

                    anchors.verticalCenter: parent.verticalCenter

                    Rectangle {
                        x: autostartSwitch.checked ? parent.width - width - 2 : 2
                        y: 2
                        width: 22
                        height: 22
                        radius: 11
                        color: autostartSwitch.checked ? Theme.on_primary : Theme.outline
                        Behavior on x { NumberAnimation { duration: 150 } }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.NoButton
                }

                onClicked: {
                    if (!ready) return;
                    if (checked) {
                        Quickshell.execDetached(["rm", "-f", Quickshell.env("HOME") + "/.cache/ml4w-welcome-autostart"]);
                    } else {
                        Quickshell.execDetached(["touch", Quickshell.env("HOME") + "/.cache/ml4w-welcome-autostart"]);
                    }
                }
            }
        }
    }
}
