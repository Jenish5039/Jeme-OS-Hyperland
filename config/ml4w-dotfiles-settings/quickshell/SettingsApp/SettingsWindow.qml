import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.CustomTheme
import "components"
import "pages"

FloatingWindow {
    id: root

    visible: false
    title: "Jeme OS Settings"
    implicitWidth: 960
    implicitHeight: 640
    color: Theme.background

    // Settings profile
    property string profile: Quickshell.env("PROFILE") ? Quickshell.env("PROFILE") : "com.ml4w.dotfiles"

    // Absolute path to the CLI backend script
    property string scriptPath: Quickshell.env("HOME") + "/.local/bin/ml4w-dotfiles-settings"

    property var settingsData: []
    property int selectedPageIndex: 0

    onSelectedPageIndexChanged: {
        if (mainScrollView && mainScrollView.contentItem) {
            mainScrollView.contentItem.contentY = 0;
        }
    }

    IpcHandler {
        target: "settings"
        function toggle(): void { root.visible = !root.visible }
        function open(): void { root.visible = true }
        function close(): void { root.visible = false }
        function isOpen(): bool { return root.visible }
        function openPage(pageIndex: int): void {
            root.selectedPageIndex = pageIndex;
            if (mainScrollView && mainScrollView.contentItem) {
                mainScrollView.contentItem.contentY = 0;
            }
            root.visible = true;
        }
    }

    // Load and parse settings.json configuration
    Process {
        command: ["bash", "-c", "cat ~/.config/ml4w-dotfiles-settings/" + root.profile + "/settings.json 2>&1"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                var rawOutput = this.text.trim();
                if (rawOutput === "" || rawOutput.startsWith("cat: ")) {
                    console.log("ERROR: Could not load settings.json");
                    return;
                }
                try {
                    root.settingsData = JSON.parse(rawOutput);
                } catch(e) {
                    console.log("Error parsing settings JSON: ", e);
                }
            }
        }
    }

    // Sidebar navigation data model
    readonly property var navigationItems: [
        "Home",
        "System",
        "Appearance",
        "Wallpaper",
        "Hyprland",
        "Audio",
        "Applications",
        "Notifications",
        "Dotfiles",
        "HyprMod",
        "About"
    ]

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // ==========================================
        // LEFT PERSISTENT SIDEBAR
        // ==========================================
        Rectangle {
            Layout.preferredWidth: 230
            Layout.fillHeight: true
            color: Theme.background

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 12

                // App Branding Header
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    Layout.topMargin: 4
                    Layout.bottomMargin: 4

                    Image {
                        source: "file://" + Quickshell.env("HOME") + "/.config/my-logo/logo.svg"
                        sourceSize.width: 28
                        sourceSize.height: 28
                        Layout.preferredWidth: 28
                        Layout.preferredHeight: 28
                        fillMode: Image.PreserveAspectFit
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Text {
                        text: "Settings"
                        font.family: Theme.fontFamily
                        font.pixelSize: 18
                        font.bold: true
                        color: Theme.on_background
                        Layout.alignment: Qt.AlignVCenter
                    }
                }

                // Divider line
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 1
                    color: Theme.primary
                    opacity: 0.25
                }

                // Scrollable Navigation List
                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true

                    ScrollBar.vertical: ScrollBar {
                        policy: ScrollBar.AsNeeded
                        interactive: true
                        contentItem: Rectangle {
                            implicitWidth: 4
                            radius: 2
                            color: Theme.primary
                            opacity: parent.pressed ? 1.0 : (parent.active ? 0.7 : 0.3)
                        }
                    }

                    ColumnLayout {
                        width: parent.width
                        spacing: 4

                        Repeater {
                            model: root.navigationItems

                            delegate: SidebarItem {
                                text: modelData
                                active: index === root.selectedPageIndex
                                onClicked: root.selectedPageIndex = index
                            }
                        }
                    }
                }

                // Sidebar Footer Badge
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 32
                    radius: 6
                    color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.08)

                    Text {
                        anchors.centerIn: parent
                        text: "Jeme OS 2.15.1"
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        color: Theme.primary
                        opacity: 0.8
                    }
                }
            }
        }

        // Subtle vertical separator between sidebar and main content
        Rectangle {
            Layout.preferredWidth: 1
            Layout.fillHeight: true
            color: Theme.primary
            opacity: 0.15
        }

        // ==========================================
        // RIGHT MAIN CONTENT AREA
        // ==========================================
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Theme.background

            ScrollView {
                id: mainScrollView
                anchors.fill: parent
                anchors.margins: 24
                clip: true

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                    interactive: true
                    contentItem: Rectangle {
                        implicitWidth: 6
                        radius: 3
                        color: Theme.primary
                        opacity: parent.pressed ? 1.0 : (parent.active ? 0.8 : 0.4)
                        Behavior on opacity { NumberAnimation { duration: 150 } }
                    }
                }

                ColumnLayout {
                    width: mainScrollView.width - (mainScrollView.ScrollBar.vertical.visible ? 16 : 0)
                    spacing: 0

                    HomePage {
                        visible: root.selectedPageIndex === 0
                        Layout.fillWidth: true
                        scriptPath: root.scriptPath
                        profile: root.profile
                        onNavigateTo: function(idx) { root.selectedPageIndex = idx }
                    }

                    SystemPage {
                        visible: root.selectedPageIndex === 1
                        Layout.fillWidth: true
                        settingsData: root.settingsData
                        scriptPath: root.scriptPath
                        profile: root.profile
                    }

                    AppearancePage {
                        visible: root.selectedPageIndex === 2
                        Layout.fillWidth: true
                        settingsData: root.settingsData
                        scriptPath: root.scriptPath
                        profile: root.profile
                    }

                    WallpaperPage {
                        visible: root.selectedPageIndex === 3
                        Layout.fillWidth: true
                    }

                    HyprlandPage {
                        visible: root.selectedPageIndex === 4
                        Layout.fillWidth: true
                    }

                    AudioPage {
                        visible: root.selectedPageIndex === 5
                        Layout.fillWidth: true
                    }

                    ApplicationsPage {
                        visible: root.selectedPageIndex === 6
                        Layout.fillWidth: true
                        settingsData: root.settingsData
                        scriptPath: root.scriptPath
                        profile: root.profile
                    }

                    NotificationsPage {
                        visible: root.selectedPageIndex === 7
                        Layout.fillWidth: true
                    }

                    DotfilesPage {
                        visible: root.selectedPageIndex === 8
                        Layout.fillWidth: true
                    }

                    HyprModPage {
                        visible: root.selectedPageIndex === 9
                        Layout.fillWidth: true
                    }

                    AboutPage {
                        visible: root.selectedPageIndex === 10
                        Layout.fillWidth: true
                    }
                }
            }
        }
    }
}