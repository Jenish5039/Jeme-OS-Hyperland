import Quickshell
import Quickshell.Services.SystemTray
import QtQuick
import QtQuick.Layouts
import qs.CustomTheme

// Omarchy-styled System tray (StatusNotifierItem hosts) for Jeme OS.
// Provides tactile capsule slots for each indicator icon with smooth hover and click scaling.
RowLayout {
    id: tray
    spacing: 6

    readonly property bool collapsed: SystemTray.items.values.length === 0
    property int openMenuCount: 0
    readonly property bool menuOpen: openMenuCount > 0

    Repeater {
        model: SystemTray.items

        delegate: Rectangle {
            id: traySlot
            required property var modelData

            readonly property bool isIBus:
                modelData.title.toLowerCase().includes("ibus") ||
                modelData.tooltipTitle.toLowerCase().includes("ibus") ||
                modelData.tooltipDescription.toLowerCase().includes("ibus")

            readonly property bool isWifi: {
                const id = (traySlot.modelData.id || "").toLowerCase()
                const title = (traySlot.modelData.title || "").toLowerCase()
                const tt = (traySlot.modelData.tooltipTitle || "").toLowerCase()
                return id.includes("nm_applet") || id.includes("nm-applet") ||
                       title.includes("nm-applet") || title.includes("nm_applet") ||
                       tt.includes("nm-applet") || tt.includes("nm_applet")
            }

            readonly property bool isBluetooth: {
                const id = (traySlot.modelData.id || "").toLowerCase()
                const title = (traySlot.modelData.title || "").toLowerCase()
                const tt = (traySlot.modelData.tooltipTitle || "").toLowerCase()
                return id.includes("blueman") || title.includes("blueman") || tt.includes("blueman")
            }

            visible: !isIBus
            implicitWidth: isIBus ? 0 : 26
            implicitHeight: isIBus ? 0 : 26
            radius: 13
            Layout.alignment: Qt.AlignVCenter

            readonly property bool hovered: mouseArea.containsMouse

            color: hovered ? Theme.surface_container_highest : "transparent"
            border.color: hovered ? Theme.outline : "transparent"
            border.width: hovered ? 1 : 0

            Behavior on color {
                ColorAnimation { duration: 200; easing.type: Easing.OutQuint }
            }
            Behavior on border.color {
                ColorAnimation { duration: 200; easing.type: Easing.OutQuint }
            }

            scale: mouseArea.pressed ? 0.92 : (hovered ? 1.05 : 1.0)
            Behavior on scale {
                NumberAnimation { duration: 150; easing.type: Easing.OutBack }
            }

            Image {
                anchors.centerIn: parent
                source: traySlot.modelData.icon
                width: 16
                height: 16
                sourceSize.width: 16
                sourceSize.height: 16
                fillMode: Image.PreserveAspectFit
            }

            MouseArea {
                id: mouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton

                onClicked: (mouse) => {
                    if (mouse.button === Qt.LeftButton && traySlot.isWifi) {
                        Quickshell.execDetached(["qs", "ipc", "call", "connectivity", "toggleWifi"])
                    } else if (mouse.button === Qt.LeftButton && traySlot.isBluetooth) {
                        Quickshell.execDetached(["qs", "ipc", "call", "connectivity", "toggleBluetooth"])
                    } else if (mouse.button === Qt.LeftButton && !traySlot.modelData.onlyMenu) {
                        traySlot.modelData.activate()
                    } else if (traySlot.modelData.hasMenu) {
                        trayMenu.open()
                    }
                }
            }

            QsMenuAnchor {
                id: trayMenu
                menu: traySlot.modelData.menu
                anchor.item: traySlot
                anchor.edges: Edges.Bottom
                anchor.gravity: Edges.Bottom

                onOpened: tray.openMenuCount++
                onClosed: tray.openMenuCount--
            }
        }
    }
}
